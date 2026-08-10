using Azure;
using Azure.AI.Translation.Text;
using Azure.Identity;

string? endpoint = Environment.GetEnvironmentVariable("TRANSLATOR_ENDPOINT");
string targetLanguage = args.ElementAtOrDefault(0) ?? Environment.GetEnvironmentVariable("TARGET_LANGUAGE") ?? "de";
string? sourceLanguage = Environment.GetEnvironmentVariable("SOURCE_LANGUAGE");
string text = args.ElementAtOrDefault(1) ?? Environment.GetEnvironmentVariable("TEXT") ?? "Hello from Azure AI Translator.";
string? deploymentName = args.ElementAtOrDefault(2) ?? Environment.GetEnvironmentVariable("TRANSLATOR_DEPLOYMENT_NAME");

if (string.IsNullOrWhiteSpace(endpoint))
{
    Console.Error.WriteLine("Set TRANSLATOR_ENDPOINT to your resource-specific endpoint before running the sample.");
    Console.Error.WriteLine("Usage: dotnet run --project src/LlmTextTranslation.Sample -- <target-language> <text>");
    return 1;
}

TextTranslationClient client = new(new DefaultAzureCredential(), new Uri(endpoint));
IReadOnlyList<TranslatedTextItem> translations;
if (string.IsNullOrWhiteSpace(deploymentName))
{
    Console.WriteLine("Translation route: NLP");
    Response<IReadOnlyList<TranslatedTextItem>> response = await client.TranslateAsync(targetLanguage, text, sourceLanguage);
    translations = response.Value;
}
else
{
    Console.WriteLine($"Translation route: LLM ({deploymentName})");
    TranslationTarget target = new(targetLanguage, deploymentName: deploymentName);
    TranslateInputItem input = new(text, target, language: sourceLanguage);
    Response<TranslatedTextItem> response = await client.TranslateAsync(input);
    translations = [response.Value];
}

foreach (TranslatedTextItem item in translations)
{
    foreach (TranslationText translation in item.Translations)
    {
        Console.WriteLine($"{translation.Language}: {translation.Text}");
    }
}

return 0;
