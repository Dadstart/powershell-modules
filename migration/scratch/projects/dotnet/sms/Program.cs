namespace sms;

using Telnyx;
class Program
{
    private static string TELNYX_API_KEY = System.Environment.GetEnvironmentVariable("TELNYX_API_KEY");
    static async Task Main(string[] args)
    {
        Console.WriteLine("Hello World!");
        TelnyxConfiguration.SetApiKey(TELNYX_API_KEY);
        MessagingSenderIdService service = new MessagingSenderIdService();
        NewMessagingSenderId options = new NewMessagingSenderId
        {
            From = "+15122548579", // alphanumeric sender id
            To = "+14254571489",
            Text = "Hello, World!",            
        };
        MessagingSenderId messageResponse = await service.CreateAsync(options);
        /*
        Console.WriteLine(messageResponse.Approved);
        Console.WriteLine(messageResponse.CreatedAt);
        Console.WriteLine(messageResponse.Id);
        Console.WriteLine(messageResponse.MessagingProfileId);
        Console.WriteLine(messageResponse.OrganizationId);
        Console.WriteLine(messageResponse.RecordType);
        Console.WriteLine(messageResponse.SenderId);
        Console.WriteLine(messageResponse.UpdatedAt);
        */
        Console.WriteLine(messageResponse.ToJson());
    }
}
