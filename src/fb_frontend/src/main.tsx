import React from 'react';
import ReactDOM from 'react-dom/client';
import { AuthClient } from '@dfinity/auth-client';
import App from './App';
import './index.scss';
import { constants } from '@lib/constants';

const identityProvider = constants.cwa.identityProvider;
const root = ReactDOM.createRoot(document.getElementById('root')!);
const init = async () => {
  const authClient = await AuthClient.create();
  const isAuthenticated = await authClient.isAuthenticated();

  if (isAuthenticated) {
    await handleAuthenticated(authClient);
  } else {
    console.log("main -> init -> Not logged in. Local?", constants.env.local, "identityProvider", identityProvider);
    // Call authClient.login(...) to login with Internet Identity. This will open a new tab
    // with the login prompt. The code has to wait for the login process to complete.
    // We can either use the callback functions directly or wrap in a promise.
    await authClient.login({
      // 7 days in nanoseconds
      maxTimeToLive: BigInt(7 * 24 * 60 * 60 * 1000 * 1000 * 1000),
      identityProvider: identityProvider,
      onSuccess: async () => {
        handleAuthenticated(authClient);
      }
    });
  }
}

async function handleAuthenticated(authClient: AuthClient) {
  // Get the identity from the auth client:
  const identity = authClient.getIdentity();
  const userPrincipal = identity.getPrincipal();
  // console.log(userPrincipal);
  console.log("main -> handleAuthenticated -> logged in with principal:", userPrincipal.toLocaleString(), "Anonymous:", userPrincipal.isAnonymous(), "identityProvider", identityProvider);

  root.render(
    <React.StrictMode>
      <App loggedInPrincipal={userPrincipal} />
    </React.StrictMode>
  );
}

init();
