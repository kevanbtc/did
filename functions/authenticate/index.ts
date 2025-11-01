import { AzureFunction, Context, HttpRequest } from "@azure/functions"
import { SecretClient } from "@azure/keyvault-secrets"
import { DefaultAzureCredential } from "@azure/identity"

const authenticate: AzureFunction = async function (context: Context, req: HttpRequest): Promise<void> {
  context.log("Authenticate function triggered", {
    method: req.method,
    url: req.url,
    timestamp: new Date().toISOString()
  })

  try {
    // Validate request
    if (req.method !== "POST") {
      context.res = {
        status: 405,
        body: { error: "Method not allowed. Use POST." }
      }
      return
    }

    const { username, password, email } = req.body

    if (!username || !password) {
      context.res = {
        status: 400,
        body: {
          error: "Missing required fields: username and password"
        }
      }
      return
    }

    // Verify email format
    if (email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      context.res = {
        status: 400,
        body: { error: "Invalid email format" }
      }
      return
    }

    // Get API keys from Key Vault
    const keyVaultUrl = process.env.KeyVaultUri
    if (!keyVaultUrl) {
      throw new Error("KeyVaultUri not configured")
    }

    const credential = new DefaultAzureCredential()
    const client = new SecretClient(keyVaultUrl, credential)

    // Try to get OpenAI key (for demonstration)
    let openaiKey: string
    try {
      const secret = await client.getSecret("openai-api-key")
      openaiKey = secret.value || ""
    } catch (error) {
      context.log.error("Failed to retrieve OpenAI key from Key Vault", error)
      openaiKey = "placeholder"
    }

    // Simulate authentication (in production, validate against actual auth system)
    const isAuthenticated = username.length > 0 && password.length > 6

    if (!isAuthenticated) {
      context.res = {
        status: 401,
        body: {
          error: "Authentication failed"
        }
      }
      return
    }

    // Generate a mock credential
    const credential_jwt = generateMockJWT(username, email)

    context.res = {
      status: 200,
      headers: {
        "Content-Type": "application/json"
      },
      body: {
        success: true,
        message: "Authentication successful",
        credential: {
          type: "VerifiableCredential",
          issuer: "did:example:issuer",
          issuanceDate: new Date().toISOString(),
          credentialSubject: {
            username,
            email: email || `${username}@example.com`
          },
          jwt: credential_jwt
        },
        token: credential_jwt,
        expiresIn: 3600
      }
    }

    context.log("Authentication successful", { username, email })
  } catch (error) {
    context.log.error("Authenticate function error", error)
    context.res = {
      status: 500,
      body: {
        error: "Internal server error",
        message: error instanceof Error ? error.message : "Unknown error"
      }
    }
  }
}

function generateMockJWT(username: string, email?: string): string {
  const header = Buffer.from(JSON.stringify({ alg: "HS256", typ: "JWT" })).toString("base64")
  const payload = Buffer.from(
    JSON.stringify({
      sub: username,
      email: email || `${username}@example.com`,
      iat: Math.floor(Date.now() / 1000),
      exp: Math.floor(Date.now() / 1000) + 3600
    })
  ).toString("base64")
  const signature = "mock_signature"

  return `${header}.${payload}.${signature}`
}

export default authenticate
