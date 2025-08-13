import { MongoClient, Db } from 'mongodb'

let client: MongoClient | null = null
let dbConnection: Db | null = null

async function connectToDatabase() {
  if (dbConnection) {
    return dbConnection
  }

  try {
    let mongoUri: string
    
    // Running on AWS - use Secrets Manager
    try {
      // Dynamic import of AWS secrets module only when needed
      const awsSecretsModule = await import('./aws-secrets')
      mongoUri = await awsSecretsModule.getMongoDBUri()
      console.log('✅ Retrieved MongoDB URI from AWS Secrets Manager (AWS environment)')
    } catch (secretsError) {
      // Fallback to environment variable if Secrets Manager fails
      mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/feedbackhub'
      if (process.env.MONGODB_URI) {
        console.log('⚠️  Secrets Manager failed, using MONGODB_URI fallback (AWS environment)')
      } else {
        console.log('⚠️  Secrets Manager failed, using default localhost fallback (AWS environment)')
      }
    }

    client = new MongoClient(mongoUri)
    await client.connect()
    dbConnection = client.db()

    console.log('✅ Successfully connected to MongoDB.')
    return dbConnection
  } catch (error) {
    console.error('❌ MongoDB connection failed:', error)
    throw new Error('Could not connect to the database.')
  }
}

export async function getDb(): Promise<Db> {
  const db = await connectToDatabase()
  if (!db) {
    throw new Error('Database not connected')
  }
  return db
}

export async function closeConnection(): Promise<void> {
  if (client) {
    await client.close()
    client = null
    dbConnection = null
    console.log('🔌 MongoDB connection closed.')
  }
}

export function mongoConfig() {
  return {
    uri: 'From AWS Secrets Manager',
    database: 'feedbackhub',
    username: 'from-secrets-manager',
    environment: process.env.NODE_ENV || 'production',
    strategy: 'aws-secrets-manager'
  }
}
