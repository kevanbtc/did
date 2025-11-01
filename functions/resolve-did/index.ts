import { AzureFunction, Context, HttpRequest } from "@azure/functions"

const resolveDID: AzureFunction = async function (context: Context, req: HttpRequest): Promise<void> {
  context.log("Resolve DID function triggered", {
    method: req.method,
    url: req.url,
    timestamp: new Date().toISOString()
  })

  try {
    if (req.method !== "GET") {
      context.res = {
        status: 405,
        body: { error: "Method not allowed. Use GET." }
      }
      return
    }

    const did = req.params.did || req.query.did

    if (!did) {
      context.res = {
        status: 400,
        body: { error: "Missing required parameter: did" }
      }
      return
    }

    // Validate DID format
    if (!did.startsWith("did:")) {
      context.res = {
        status: 400,
        body: { error: "Invalid DID format. Must start with 'did:'" }
      }
      return
    }

    // Parse DID
    const didParts = did.split(":")
    if (didParts.length < 3) {
      context.res = {
        status: 400,
        body: { error: "Invalid DID format. Expected format: did:method:identifier" }
      }
      return
    }

    const method = didParts[1]
    const identifier = didParts.slice(2).join(":")

    // Resolve DID document (mock implementation)
    const didDocument = resolveDIDDocument(did, method, identifier)

    context.res = {
      status: 200,
      headers: {
        "Content-Type": "application/ld+json"
      },
      body: {
        success: true,
        message: "DID resolved successfully",
        didDocument: didDocument
      }
    }

    context.log("DID resolved successfully", { did: did })
  } catch (error) {
    context.log.error("Resolve DID function error", error)
    context.res = {
      status: 500,
      body: {
        error: "Internal server error",
        message: error instanceof Error ? error.message : "Unknown error"
      }
    }
  }
}

function resolveDIDDocument(did: string, method: string, identifier: string): any {
  return {
    "@context": "https://www.w3.org/ns/did/v1",
    id: did,
    authentication: [
      `${did}#keys-1`
    ],
    assertionMethod: [
      `${did}#keys-2`
    ],
    verificationMethod: [
      {
        id: `${did}#keys-1`,
        type: "Ed25519VerificationKey2020",
        controller: did,
        publicKeyMultibase: "z6MkhaXgBZDvotDkL5257faWxcqyy4MIzkwxgaBo1qXrQi5L"
      },
      {
        id: `${did}#keys-2`,
        type: "Ed25519VerificationKey2020",
        controller: did,
        publicKeyMultibase: "z6MkhaXgBZDvotDkL5257faWxcqyy4MIzkwxgaBo1qXrQi5M"
      }
    ],
    service: [
      {
        id: `${did}#endpoint-1`,
        type: "VerifiableCredentialService",
        serviceEndpoint: "https://did-ecosystem.azurewebsites.net/api"
      },
      {
        id: `${did}#endpoint-2`,
        type: "LinkedDomains",
        serviceEndpoint: "https://identity.did-ecosystem.local"
      }
    ],
    created: new Date().toISOString(),
    updated: new Date().toISOString(),
    proof: {
      type: "Ed25519Signature2020",
      verificationMethod: `${did}#keys-1`,
      signatureValue: "eyJhbGciOiJFZERTQSIsImtpZCI6IiNrZXlzLTEifQ"
    }
  }
}

export default resolveDID
