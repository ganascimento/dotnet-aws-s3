using Amazon;
using Amazon.Runtime;
using Amazon.S3;

namespace Dotnet.Aws.S3.API.Configs;

public static class AwsConfigure
{
    public static IServiceCollection AwsConfig(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddSingleton<IAmazonS3>(sp =>
        {
            var awsOptions = configuration.GetSection("AWS");

            var region = awsOptions["Region"] ?? throw new InvalidDataException("Region not found!");
            var accessKey = awsOptions["AccessKey"];
            var secretKey = awsOptions["SecretKey"];

            if (!string.IsNullOrEmpty(accessKey) && !string.IsNullOrEmpty(secretKey))
            {
                var credentials = new BasicAWSCredentials(accessKey, secretKey);
                return new AmazonS3Client(credentials, RegionEndpoint.GetBySystemName(region));
            }
            else
            {
                return new AmazonS3Client(RegionEndpoint.GetBySystemName(region));
            }
        });

        return services;
    }
}