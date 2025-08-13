// AWS SDK imports are dynamic to avoid bundling issues in local development

let secretsClient: any = null

async function getSecretsClient() {
  if (!secretsClient) {
    try {
      // Dynamic import of AWS SDK only when actually needed
      const { SecretsManagerClient } = await import('@aws-sdk/client-secrets-manager')
      secretsClient = new SecretsManagerClient({
        region: process.env.AWS_REGION || 'us-east-1',
      })
    } catch (importError) {
      throw new Error('AWS SDK not available - this should only run in AWS environment')
    }
  }
  return secretsClient
}

export async function getSecret(secretName: string): Promise<string> {
  try {
    const client = await getSecretsClient()
    // Dynamic import of the command class
    const { GetSecretValueCommand } = await import('@aws-sdk/client-secrets-manager')
    const command = new GetSecretValueCommand({
      SecretId: secretName,
    })
    
    const response = await client.send(command)
    
    if (response.SecretString) {
      return response.SecretString
    }
    
    throw new Error(`Secret ${secretName} has no string value`)
  } catch (error) {
    console.error(`❌ Failed to retrieve secret ${secretName}:`, error)
    throw new Error(`Could not retrieve secret: ${secretName}`)
  }
}

export async function getMongoDBUri(): Promise<string> {
  const secretName = process.env.FEEDBACKHUB_SECRET_NAME
  if (!secretName) {
    throw new Error('FEEDBACKHUB_SECRET_NAME environment variable not set')
  }
  
  const secretString = await getSecret(secretName)
  
  try {
    // Parse the JSON secret and extract MONGODB_URI
    const secretData = JSON.parse(secretString)
    if (secretData.MONGODB_URI) {
      return secretData.MONGODB_URI
    }
    throw new Error('MONGODB_URI not found in secret data')
  } catch (parseError) {
    console.error(`❌ Failed to parse secret JSON:`, parseError)
    throw new Error('Invalid secret format - expected JSON with MONGODB_URI field')
  }
}
