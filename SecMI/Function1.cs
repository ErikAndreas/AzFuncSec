using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Azure.WebJobs.Extensions.SignalRService;
using Dapper;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using System;
using System.Threading.Tasks;
using System.IO;
using Azure.Storage.Blobs;
using System.Text;
using Azure.Security.KeyVault.Secrets;
using Azure.Identity;
using Microsoft.IdentityModel.Protocols;
using Microsoft.IdentityModel.Protocols.OpenIdConnect;
using System.Threading;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Newtonsoft.Json;

namespace SecMI
{
    public static class SecMI
    {
        private const string AUTH_HEADER_NAME = "Authorization";
        private const string BEARER_PREFIX = "Bearer ";
        private static string ISSUER = $"https://login.microsoftonline.com/{Environment.GetEnvironmentVariable("AAD_TENANTID")}/v2.0";  
        private static string AUDIENCE = Environment.GetEnvironmentVariable("AAD_CLIENTID");

        [FunctionName("Index")]
        public static IActionResult GetHomePage(
            [HttpTrigger(AuthorizationLevel.Anonymous)] HttpRequest req, Microsoft.Azure.WebJobs.ExecutionContext context)
        {
            var path = Path.Combine(context.FunctionAppDirectory, "site", "index.html");
            return new ContentResult
            {
                Content = File.ReadAllText(path),
                ContentType = "text/html",
            };
        }

        [FunctionName("SecuredEndpoint")]
        public static async Task<IActionResult> SecuredEndpoint(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "secendpoint")] HttpRequest req,
            ILogger log)
        {
            var accessToken = "";
            // sample code validating accessToken
            if (req.Headers.ContainsKey(AUTH_HEADER_NAME) &&
                req.Headers[AUTH_HEADER_NAME].ToString().StartsWith(BEARER_PREFIX, StringComparison.OrdinalIgnoreCase))
            {
                accessToken = req.Headers[AUTH_HEADER_NAME].ToString().Substring(BEARER_PREFIX.Length);
            }
            else
            {
                return new ForbidResult();
            }

            HttpDocumentRetriever documentRetriever = new HttpDocumentRetriever { RequireHttps = ISSUER.StartsWith("https://", StringComparison.OrdinalIgnoreCase) };

            var _configurationManager = new ConfigurationManager<OpenIdConnectConfiguration>(
                $"https://login.microsoftonline.com/{Environment.GetEnvironmentVariable("AAD_TENANTID")}/v2.0/.well-known/openid-configuration",
                new OpenIdConnectConfigurationRetriever(),
                documentRetriever);

            OpenIdConnectConfiguration openIdConfig = await _configurationManager.GetConfigurationAsync(CancellationToken.None);

            TokenValidationParameters validationParameters = new TokenValidationParameters
            {
                RequireSignedTokens = true,
                ValidAudience = AUDIENCE,
                ValidateAudience = true,
                ValidIssuer = ISSUER,
                ValidateIssuer = true,
                ValidateIssuerSigningKey = true,
                ValidateLifetime = true,
                IssuerSigningKeys = openIdConfig.SigningKeys
            };

            ClaimsPrincipal principal = new ClaimsPrincipal();
            try
            {
                log.LogDebug("Validation starting");
                JwtSecurityTokenHandler tokenHandler = new JwtSecurityTokenHandler();
                tokenHandler.InboundClaimTypeMap.Clear();
                principal = tokenHandler.ValidateToken(accessToken, validationParameters, out SecurityToken token);
                log.LogDebug("Validation complete");
                foreach (Claim c in principal.Claims)
                {
                    log.LogInformation($"{c.Type} {c.Value}");
                }
            }
            catch (Exception ex)
            {
                log.LogError(ex.Message);
                return new ForbidResult();
            }

            return new JsonResult("ok");
        }

        [FunctionName("SQLServer")]
        public static async Task<IActionResult> SQLServer(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", "post", Route = "sql")] HttpRequest req,
            ILogger log)
        {
            string sql = "SELECT * FROM test";
            using (var conn = new SqlConnection(Environment.GetEnvironmentVariable("DbConnStr")))
            {
                var result = await conn.QueryAsync<Data>(sql);
                return new OkObjectResult(result);
            }
        }

        [FunctionName("Storage")]
        public static async Task<IActionResult> Storage(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "storage")] HttpRequest req,
            [Blob("test", FileAccess.Read, Connection = "StorageConnStr")] BlobContainerClient blobContainer,
            ILogger log)
        {
            await blobContainer.CreateIfNotExistsAsync();
            BlobClient blobClient = blobContainer.GetBlobClient("testfile.txt");
            string content = "file content";
            await blobClient.UploadAsync(new MemoryStream(Encoding.UTF8.GetBytes(content)), overwrite: true);
            return new OkObjectResult(content);
        }


        [FunctionName("KeyVault")]
        public static async Task<IActionResult> KeyVault(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", "post", Route = "keyvault")] HttpRequest req,
        ILogger log)
        {
            // key vault secrets can also be fetched directly but this is slow and requires both Azure.Security.KeyVault.Secrets and Azure.Identity !
            var client = new SecretClient(vaultUri: new Uri($"https://{Environment.GetEnvironmentVariable("KeyVaultName")}.vault.azure.net/"), new DefaultAzureCredential());
            var secret = await client.GetSecretAsync("secret1");
            log.LogInformation($"straight from key vault: {secret.Value.Value}");

            // preferred 
            return new OkObjectResult(Environment.GetEnvironmentVariable("SecretVar"));
        }

        [FunctionName("SignalR")]
        public static async Task<IActionResult> SignalR(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", "post", Route = "signalr")] HttpRequest req,
        [SignalR(HubName = "serverless")] IAsyncCollector<SignalRMessage> signalRMessages,
        ILogger log)
        {
            await signalRMessages.AddAsync(
                new SignalRMessage
                {
                    Target = "newMessage",
                    Arguments = new[] { $"Hi at {new DateTime()}" }
                });
            return new OkObjectResult("sent");
        }
    }

    class Data
    {
        public string Id { get; set; }
        public string Testa { get; set; }
        public string Testb { get; set; }
        public DateTime Created { get; set; }
    }
}
