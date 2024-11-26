# `Family Bank`

A decentralised take on family-controlled fund management.

### Table of Contents

* [Family Bank Explained](#family-bank-explained)
  * [What is it?](#what-is-it?)
    * [Funds](#fund) | [Members](#member) | [Pots](#pot) | [Transactions](#transaction)
  * [Utilising ckBTC](#utilising-ckbtc)
* [Setup](#setup)
  * [Running locally](#running-the-project-locally)
    * [Bitcoin Node](#Running-Bitcoin-Node) | [IC SDK](#Running-IC-SDK) | [ckBTC Ledger](#Deploy-ckBTC-Ledger-Canister)
    * [Environment variables](#note-on-frontend-environment-variables) | [Resolving 403 Issues](#resolving-403-issues)
  * [Deploying on the IC](#Deploying-on-the-IC)
* [Resources](#resources)

## Family Bank Explained
### What is it?

A family bank is a **fund** managed by closely-related and/or value-aligned members of a family, group, society or organisation.
The primary goal of the fund is to **grow wealth** collectively through **investments** by managing a diversified portfolio.
A secondary goal is to allow members to take out a **loan** for various purposes such as emergency spending, house purchase deposit, car purchase, etc. 

**Disclaimer:** Our implementation promotes a **goodly interest-free loan**, also known as [**Qard-al-Hasan**](https://en.wikipedia.org/wiki/Qard_al-Hasan) in *Islamic Jurispudence*. We are strictly against **interest** of any kind, so our implementation makes no effort to support this monetary vehicle.

The major **components** of the family bank are the following:

* [Funds](#fund)
* [Members](#member)
* [Pots](#pot)
* [Transactions](#transaction)

#### Fund

Umbrella structure referring to the assets under management for a group of users. The fund comprises of **members**, **pots**, **transactions** and **assets**.

#### Member

Participating users within a **fund**. Members can have various roles such as **head**, **fund manager**, and **contributor**.

#### Pot

A defined **segment within a fund element, e.g., loan pot, debt repayment pot, etc.

#### Transaction

A record capturing the state of incoming and outgoing assets, as well as intermediary transformations such as currency conversions, stock purchase and sales, and realised losses.

### Utilising ckBTC

* Moving assets between **pots** frictionlessly and with minimal fees.
* ...

## Setup

This project depends on the [ICP Bitcoin integration](https://internetcomputer.org/docs/current/developer-docs/multi-chain/bitcoin/overview) and the [ICRC-1 ledger](https://internetcomputer.org/docs/current/developer-docs/defi/tokens/ledger/setup/icrc1_ledger_setup).

### Running the project locally
#### Running Bitcoin Node

For local testing, you should start the [bitcoin node](https://internetcomputer.org/docs/current/developer-docs/multi-chain/bitcoin/using-btc/local-development):

```bash
(cd ~/bitcoin-27.0 && ./bin/bitcoind -conf=$(pwd)/data/bitcoin.conf -datadir=$(pwd)/data --port=18444)
```

BTC can be mined for your canister by mining blocks for `<your-canister-btc-address>` and then generating an additional **100** blocks to satisfy the [Coinbase maturity rule](https://github.com/bitcoin/bitcoin/blob/bace615ba31cedec50afa4f296934a186b9afae6/src/consensus/consensus.h#L19):

```bash
(cd ~/bitcoin-27.0 && ./bin/bitcoin-cli -conf=$(pwd)/data/bitcoin.conf generatetoaddress 1 <your-canister-btc-address>) # mine block
(cd ~/bitcoin-27.0 && ./bin/bitcoin-cli -conf=$(pwd)/data/bitcoin.conf generatetoaddress 100 mtbZzVBwLnDmhH4pE9QynWAgh6H3aC1E6M) # coinbase maturity - BTC can only be spent after 100 blocks, so mine 100 blocks and give reward to a random address.
```

where `<your-canister-btc-address>` is the address you obtained from calling the `get_p2pkh_address` endpoint on your canister.

#### Running IC SDK

```bash
# Starts the replica, running in the background
dfx start --clean --background
```

#### Deploy ckBTC Ledger Canister

The responsibilities of the ledger canister is to keep track of token balances and handle token transfers.

The ckBTC ledger canister is already deployed on the IC mainnet. ckBTC implements the [ICRC-1](https://internetcomputer.org/docs/current/developer-docs/integrations/icrc-1/) token standard. For local development, we deploy the ledger for an ICRC-1 token mimicking the mainnet setup, and also an [index canister](https://internetcomputer.org/docs/current/developer-docs/defi/tokens/indexes) for querying transactions for accounts.

When deploying locally, we are configuring the following ledger properties:

- Deploying the canister to the same canister ID as the mainnet ledger canister. This is to make it easier to switch between local and mainnet deployments.
- Naming the token `Local ckBTC / LCKBTC`
- Setting the owner principal. Make sure you set this beforehand, e.g. `export OWNER=$(dfx identity get-principal)`
- Minting `100_000_000_000` tokens to the owner principal.
- Setting the transfer fee to `10` **LCKBTC**.

```bash
dfx deploy --network local --specified-id mxzaz-hqaaa-aaaar-qaada-cai icrc1_ledger --argument '
  (variant {
    Init = record {
      token_name = "Local ckBTC";
      token_symbol = "LCKBTC";
      minting_account = record {
        owner = principal "'${OWNER}'";
      };
      initial_balances = vec {
        record {
          record {
            owner = principal "'${OWNER}'";
          };
          100_000_000_000;
        };
      };
      metadata = vec {};
      transfer_fee = 10;
      archive_options = record {
        trigger_threshold = 2000;
        num_blocks_to_archive = 1000;
        controller_id = principal "'${OWNER}'";
      }
    }
  })
'
```

To verify correct installation, call the **icrc1_ledger** canister and check the returned data matches the expected output.

```bash
dfx canister call icrc1_ledger icrc1_symbol '()'
```

Next, we need to deploy the index canister, which syncs the ledger transactions and indexes them by account.
Here it is assumed that the canister ID of your local ICRC-1 ledger is `mxzaz-hqaaa-aaaar-qaada-cai`, otherwise replace it with your ICRC-1 ledger canister ID.

```bash
dfx deploy --network local icrc1_index --argument '
  (opt variant {
    Init = record {
      ledger_id = principal "mxzaz-hqaaa-aaaar-qaada-cai";
      retrieve_blocks_from_ledger_interval_seconds = opt 10;
    }
  })
'
```

If this fails with an error for a missing wallet canister, the easiest resolution is to delete `.dfx/local/wallets.json`, so that the local cycles wallet can be properly created. Running any wallet comamnd such as `dfx wallet name` should then go ahead and create the local cycles wallet for you.

To verify correct installation, call the **icrc1_index** canister and check the returned data matches the expected output.

```bash
dfx canister call icrc1_index ledger_id '()'
```

#### Deploying FB Canisters

To deploy the back-end canister:

```bash
dfx deploy --network local fb_backend --argument '(variant { regtest })'
```

```bash
# Deploys all canisters to the replica and generates the candid interfaces
dfx deploy
```

Once the job completes, your application will be available at `http://{asset_canister_id}.localhost:4943`.

If you have made changes to your backend canister, you can generate a new candid interface with

```bash
npm run prebuild
```

at any time. This is recommended before starting the frontend development server, and will be run automatically any time you run `dfx deploy`.

If you are making frontend changes, you can start a development server with

```bash
npm start
```

Which will start a server at `http://localhost:8080`, proxying API requests to the replica at port 4943.

#### Note on frontend environment variables

If you are hosting frontend code somewhere without using DFX, you may need to make one of the following adjustments to ensure your project does not fetch the root key in production:

- set`DFX_NETWORK` to `ic` if you are using Webpack
- use your own preferred method to replace `process.env.DFX_NETWORK` in the autogenerated declarations
  - Setting `canisters -> {asset_canister_id} -> declarations -> env_override to a string` in `dfx.json` will replace `process.env.DFX_NETWORK` with the string in the autogenerated declarations
- Write your own `createActor` constructor

### Resolving [CSP](https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP) Issues

* Add `http://127.0.0.1:*` in `src/fb_frontend/public/.ic-assets.json5`

```bash
"Content-Security-Policy": "default-src 'self';script-src 'self';connect-src 'self' http://127.0.0.1:* http://localhost:* https://icp0.io https://*.icp0.io https://icp-api.io;img-src 'self' data:;style-src * 'unsafe-inline';style-src-elem * 'unsafe-inline';font-src *;object-src 'none';base-uri 'self';frame-ancestors 'none';form-action 'self';upgrade-insecure-requests;"
```

#### Resolving 403 Issues

In the **local** environment, this is usually due to using the network Internet Identity provider instead of using the [local instance](https://internetcomputer.org/docs/current/tutorials/developer-journey/level-3/3.5-identities-and-auth#importing-the-auth-client-package).

In the front-end canister, change the `auth-client` **identityProvider** over to: `${ii_canister_id}.localhost:4943#authorize`

Also:

* Use URLs of the format `http://{asset_canister_id}.localhost:4943` instead of `http://localhost:4943/?canisterId={asset_canister_id}`
* For candid, you would use the following URL: `http://{candid_canister_id}.localhost:4943/?id={target_canister_id}`

### Deploying on the IC

```bash
dfx canister create fb_backend --with-cycles 5_000_000_000_000 --network ic # 5 TC
dfx canister create fb_frontend --next-to FB_BACKEND_CANISTER_ID --with-cycles 5_000_000_000_000 --network ic # 5 TC
dfx deploy fb_backend --argument '(variant { testnet }) --network ic' # mainnet not supported as of now
dfx deploy fb_frontend --network ic
```

## Roadmap

* **SNS DAO** implementation to make owners of funds governance token the custodians of their respective funds.
* **DEX** integration to enable hassle-free swaps for managing the investment portfolio.

## Resources

```bash
dfx build fb_frontend
dfx canister install fb_frontend --mode='reinstall'
```

- [Quick Start](https://internetcomputer.org/docs/current/developer-docs/setup/deploy-locally)
- [SDK Developer Tools](https://internetcomputer.org/docs/current/developer-docs/setup/install)
- [Motoko Programming Language Guide](https://internetcomputer.org/docs/current/motoko/main/motoko)
- [Motoko Language Quick Reference](https://internetcomputer.org/docs/current/motoko/main/language-manual)
- [Motoko Bitcoin Sample](https://github.com/dfinity/examples/tree/master/motoko/basic_bitcoin)
- [Motoko POS Sample](https://github.com/dfinity/examples/edit/master/motoko/ic-pos/)
- [Motoko Token Transfer Sample](https://github.com/dfinity/examples/tree/master/motoko/token_transfer)