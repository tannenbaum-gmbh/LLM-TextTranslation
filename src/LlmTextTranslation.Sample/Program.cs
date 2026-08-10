using Azure;
using Azure.AI.Translation.Text;

string endpoint = Environment.GetEnvironmentVariable("TRANSLATOR_ENDPOINT") ?? "https://api.cognitive.microsofttranslator.com";
string? key = Environment.GetEnvironmentVariable("TRANSLATOR_KEY");
string? region = Environment.GetEnvironmentVariable("TRANSLATOR_REGION");
string targetLanguage = args.ElementAtOrDefault(0) ?? Environment.GetEnvironmentVariable("TARGET_LANGUAGE") ?? "de";
string? sourceLanguage = Environment.GetEnvironmentVariable("SOURCE_LANGUAGE");
string text = args.ElementAtOrDefault(1) ?? Environment.GetEnvironmentVariable("TEXT") ?? "Hello from Azure AI Translator.";

if (string.IsNullOrWhiteSpace(key) || string.IsNullOrWhiteSpace(region))
{
    Console.Error.WriteLine("Set TRANSLATOR_KEY and TRANSLATOR_REGION before running the sample.");
    Console.Error.WriteLine("Usage: dotnet run --project src/LlmTextTranslation.Sample -- <target-language> <text>");
    return 1;
}

TextTranslationClient client = new(new AzureKeyCredential(key), new Uri(endpoint), region);
Response<IReadOnlyList<TranslatedTextItem>> response = await client.TranslateAsync(targetLanguage, text, sourceLanguage);

foreach (TranslatedTextItem item in response.Value)
{
    foreach (TranslationText translation in item.Translations)
    {
        Console.WriteLine($"{translation.Language}: {translation.Text}");
    }
}

return 0;
