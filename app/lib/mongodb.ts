// Main MongoDB router - completely build-time safe
// This prevents any MongoDB connections during Next.js build

// Check if we're in build-time by checking if we're in a Next.js build context
// We use a combination of checks to accurately detect build vs runtime
const isBuildTime = typeof window === 'undefined' && 
                   process.env.NODE_ENV === 'production' &&
                   process.env.NEXT_PHASE === 'phase-production-build' &&
                   !process.env.AWS_ROLE_ARN

// Check if we're running on AWS (EKS) by looking for IRSA environment variables
// Also ensure we're not in local development mode
const isRunningOnAWS = process.env.AWS_ROLE_ARN && 
                      process.env.AWS_WEB_IDENTITY_TOKEN_FILE &&
                      process.env.NODE_ENV === 'production'



// Build-time safe functions - return dummy data during build
function getBuildTimeDb() {
  console.log('🔧 Build-time detected - using dummy MongoDB connection')
  return {
    collection: () => ({
      find: () => ({ toArray: async () => [] }),
      insertOne: async () => ({ insertedId: 'build-time-id' }),
      updateOne: async () => ({ modifiedCount: 0 }),
      deleteOne: async () => ({ deletedCount: 0 })
    }),
    admin: () => ({
      listCollections: () => ({ toArray: async () => [] })
    })
  }
}

// Runtime functions - only imported when actually running
async function getRuntimeDb() {
  if (isRunningOnAWS) {
    // Only import AWS module when we're actually on AWS
    // Use a completely different approach to prevent Next.js bundling
    const awsModule = await import(/* webpackIgnore: true */ './mongodb.aws')
    return awsModule.getDb()
  } else {
    // Local development - use local MongoDB
    const localModule = await import('./mongodb.local')
    return localModule.getDb()
  }
}

export async function getDb() {
  if (isBuildTime) {
    return getBuildTimeDb()
  }
  return getRuntimeDb()
}

export async function closeConnection() {
  if (isBuildTime) {
    console.log('🔧 Build-time detected - no connection to close')
    return
  }
  
  if (isRunningOnAWS) {
    const { closeConnection } = await import('./mongodb.aws')
    return closeConnection()
  } else {
    const { closeConnection } = await import('./mongodb.local')
    return closeConnection()
  }
}

export function mongoConfig() {
  if (isBuildTime) {
    return {
      uri: 'build-time-dummy',
      database: 'feedbackhub',
      username: 'build-time',
      environment: 'build',
      strategy: 'build-time-safe'
    }
  }
  
  if (isRunningOnAWS) {
    return {
      uri: 'From AWS Secrets Manager',
      database: 'feedbackhub',
      username: 'from-secrets-manager',
      environment: process.env.NODE_ENV || 'production',
      strategy: 'aws-secrets-manager'
    }
  } else {
    return {
      uri: process.env.MONGODB_URI || 'mongodb://mongo:27017/feedbackhub',
      database: 'feedbackhub',
      username: 'from-uri',
      environment: process.env.NODE_ENV || 'development',
      strategy: 'local-mongodb'
    }
  }
}

 