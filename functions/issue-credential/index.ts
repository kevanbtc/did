import { AzureFunction, Context, HttpRequest } from "@azure/functions"

const issueCredential: AzureFunction = async function (context: Context, req: HttpRequest): Promise<void> {
  context.log("Issue Credential function triggered", {
    method: req.method,
    timestamp: new Date().toISOString()
  })

  try {
    if (req.method !== "POST") {
      context.res = {
        status: 405,
        body: { error: "Method not allowed. Use POST." }
      }
      return
    }

    const { credentialSubject, issuer, type, claims } = req.body

    if (!credentialSubject || !issuer) {
      context.res = {
        status: 400,
        body: {
          error: "Missing required fields: credentialSubject and issuer"
        }
      }
      return
    }

    // Validate issuer format (should be a DID)
    if (!issuer.startsWith("did:")) {
      context.res = {
        status: 400,
        body: {
          error: "Invalid issuer format. Must be a valid DID."
        }
      }
      return
    }

    // Create new credential
    const issuanceDate = new Date()
    const expirationDate = new Date(issuanceDate.getTime() + 365 * 24 * 60 * 60 * 1000) // 1 year

    const newCredential = {
      "@context": ["https://www.w3.org/2018/credentials/v1"],
      type: type || ["VerifiableCredential"],
      issuer: issuer,
      issuanceDate: issuanceDate.toISOString(),
      expirationDate: expirationDate.toISOString(),
      credentialSubject: credentialSubject,
      claims: claims || {},
      jwt: generateMockJWT(issuer, credentialSubject),
      id: `urn:uuid:${generateUUID()}`
    }

    context.res = {
      status: 201,
      body: {
        success: true,
        message: "Credential issued successfully",
        credential: newCredential
      }
    }

    context.log("Credential issued successfully", {
      issuer: issuer,
      credentialId: newCredential.id
    })
  } catch (error) {
    context.log.error("Issue Credential function error", error)
    context.res = {
      status: 500,
      body: {
        error: "Internal server error",
        message: error instanceof Error ? error.message : "Unknown error"
      }
    }
  }
}

function generateMockJWT(issuer: string, subject: any): string {
  const header = Buffer.from(JSON.stringify({ alg: "RS256", typ: "JWT" })).toString("base64")
  const payload = Buffer.from(
    JSON.stringify({
      iss: issuer,
      sub: JSON.stringify(subject),
      iat: Math.floor(Date.now() / 1000),
      exp: Math.floor(Date.now() / 1000) + 31536000
    })
  ).toString("base64")
  const signature = "mock_signature"

  return `${header}.${payload}.${signature}`
}

function generateUUID(): string {
  return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, function (c) {
    const r = (Math.random() * 16) | 0
    const v = c === "x" ? r : (r & 0x3) | 0x8
    return v.toString(16)
  })
}

export default issueCredential
