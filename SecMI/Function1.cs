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

namespace SecMI
{
    public static class SecMI
    {
        [FunctionName("SQLServer")]
        public static async Task<IActionResult> SQLServer(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", "post", Route = "sql")] HttpRequest req,
            ILogger log)
        {
            log.LogInformation("C# HTTP trigger function processed a request.");

            string sql = "SELECT * FROM test";
            using (var conn = new SqlConnection(Environment.GetEnvironmentVariable("DbConnStr")))
            {
                /*var tokenProvider = new Azure.Identity.DefaultAzureCredential();
                var token = await tokenProvider.GetTokenAsync(new Azure.Core.TokenRequestContext(new[] { "https://database.windows.net/.default" }, tenantId: "0549e999-9365-416b-987c-c2c4c4ae2785"));
                conn.AccessToken = token.Token;
                log.LogInformation(token.Token);*/
                var result = await conn.QueryAsync<Data>(sql);
                /*SqlCommand command = new SqlCommand(sql, conn);
                await command.Connection.OpenAsync();
                var result = await command.ExecuteScalarAsync();*/
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
    }

    class Data
    {
        public string Id { get; set; }
        public string Testa { get; set; }
        public string Testb { get; set; }
        public DateTime Created { get; set; }
    }
}
