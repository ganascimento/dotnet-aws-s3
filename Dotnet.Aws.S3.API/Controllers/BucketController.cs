using Microsoft.AspNetCore.Mvc;
using Amazon.S3;
using Amazon.S3.Model;

namespace Dotnet.Aws.S3.API.Controllers;

[ApiController]
[Route("[controller]")]
public class BucketController : ControllerBase
{
    private readonly IAmazonS3 _s3Client;
    private readonly string _bucketName;

    public BucketController(IAmazonS3 s3Client, IConfiguration config)
    {
        _s3Client = s3Client;
        _bucketName = config["AWS:BucketName"] ?? throw new InvalidDataException("AWS:BucketName not found!");
    }

    [HttpGet]
    public async Task<IActionResult> GetAllFileNames()
    {
        try
        {
            var request = new ListObjectsV2Request { BucketName = _bucketName };
            var response = await _s3Client.ListObjectsV2Async(request);
            var fileNames = response.S3Objects?.Select(o => o.Key).ToList();

            return Ok(fileNames);
        }
        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpGet]
    [Route("{name}")]
    public async Task<IActionResult> GetFile([FromRoute] string name)
    {
        try
        {
            var response = await _s3Client.GetObjectAsync(_bucketName, name);
            return File(response.ResponseStream, response.Headers["Content-Type"], name);
        }
        catch (AmazonS3Exception ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            return NotFound();
        }
        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpGet]
    [Route("presigned-url")]
    public async Task<IActionResult> GetPresignedUrl([FromQuery] string fileName, [FromQuery] int minutes)
    {
        try
        {
            if (string.IsNullOrEmpty(fileName) || minutes <= 0)
                return BadRequest("Parâmetros inválidos");

            var request = new GetPreSignedUrlRequest
            {
                BucketName = _bucketName,
                Key = fileName,
                Expires = DateTime.UtcNow.AddMinutes(minutes)
            };
            var url = await _s3Client.GetPreSignedURLAsync(request);

            return Ok(new { url });
        }
        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpPost]
    [Route("upload")]
    public async Task<IActionResult> UploadFile(IFormFile file)
    {
        try
        {
            if (file == null) return BadRequest("No file uploaded");

            using var stream = file.OpenReadStream();
            var putRequest = new PutObjectRequest
            {
                BucketName = _bucketName,
                Key = file.FileName,
                InputStream = stream,
                ContentType = file.ContentType
            };

            await _s3Client.PutObjectAsync(putRequest);

            return Ok();
        }
        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpDelete]
    [Route("{name}")]
    public async Task<IActionResult> DeleteFile([FromRoute] string name)
    {
        try
        {
            await _s3Client.DeleteObjectAsync(_bucketName, name);
            return Ok();
        }
        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }
}
