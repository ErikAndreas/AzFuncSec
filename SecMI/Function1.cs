using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
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

namespace SecMI
{
    public static class SecMI
    {
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
    }

    class Data
    {
        public string Id { get; set; }
        public string Testa { get; set; }
        public string Testb { get; set; }
        public DateTime Created { get; set; }
    }
}
