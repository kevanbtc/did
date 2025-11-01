import { AzureFunction, Context, HttpRequest } from "@azure/functions"

const verifyCredential: AzureFunction = async function (context: Context, req: HttpRequest): Promise<void> {
  context.log("Verify Credential function triggered", {
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

    const { credential } = req.body

    if (!credential) {
      context.res = {
        status: 400,
        body: { error: "Missing required field: credential" }
      }
      return
    }

    // Validate credential structure
    if (!credential.type || !credential.issuer || !credential.credentialSubject) {
      context.res = {
        status: 400,
        body: {
          error: "Invalid credential format. Missing required fields."
        }
      }
      return
    }

    // Verify credential signature (mock implementation)
    const isValid = verifyCredentialSignature(credential)

    if (!isValid) {
      context.res = {
        status: 401,
        body: {
          error: "Credential verification failed - invalid signature"
        }
      }
      return
    }

    // Check expiration
    if (credential.expirationDate) {
      const expirationDate = new Date(credential.expirationDate)
      if (expirationDate < new Date()) {
        context.res = {
          status: 401,
          body: {
            error: "Credential has expired"
          }
        }
        return
      }
    }

    context.res = {
      status: 200,
      body: {
        success: true,
        message: "Credential verified successfully",
        verification: {
          isValid: true,
          issuer: credential.issuer,
          issuanceDate: credential.issuanceDate,
          expirationDate: credential.expirationDate || "Never",
          subject: credential.credentialSubject
        }
      }
    }

    context.log("Credential verified successfully", { issuer: credential.issuer })
  } catch (error) {
    context.log.error("Verify Credential function error", error)
    context.res = {
      status: 500,
      body: {
        error: "Internal server error",
        message: error instanceof Error ? error.message : "Unknown error"
      }
    }
  }
}

function verifyCredentialSignature(credential: any): boolean {
  // Mock signature verification
  // In production, this would verify cryptographic signatures
  return (
    credential.jwt !== undefined ||
    credential.proof !== undefined ||
    (credential.credentialSubject && Object.keys(credential.credentialSubject).length > 0)
  )
}

export default verifyCredential
