// Environment
const network = process.env.DFX_NETWORK || "local";
const local = network === "local" || network !== "ic";
const ic = !local;
// CWA
const replicaPort = 4943;
const host = local ? `http://127.0.0.1:${replicaPort}` : 'https://icp-api.io';
// Canisters
const iiCanisterId = process.env.CANISTER_ID_INTERNET_IDENTITY;

// Constants
export const constants = Object.freeze({
    // Environment
    env: {
        local,
        ic,
    },
    // CWA
    cwa: {
        host: host,
        identityProvider: local 
        ? `http://${iiCanisterId}.localhost:${replicaPort}#authorize` 
        : "https://identity.ic0.app/#authorize",
    },
    // Canisters
    canisters: {
        backend: {
            id: process.env.CANISTER_ID_II_INTEGRATION_BACKEND || process.env.CANISTER_ID,
        },
        frontend: {
            id: process.env.CANISTER_ID_II_INTEGRATION_FRONTEND,
        },
        ii: {
            id: iiCanisterId,
        },
    },
});