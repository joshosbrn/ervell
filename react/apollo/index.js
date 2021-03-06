import 'isomorphic-fetch';
import sharify from 'sharify';
import React from 'react';
import { ApolloProvider } from 'react-apollo';
import { ApolloClient } from 'apollo-client';
import { createHttpLink } from 'apollo-link-http';
import { setContext } from 'apollo-link-context';
import { InMemoryCache, IntrospectionFragmentMatcher } from 'apollo-cache-inmemory';

import mount from 'react/util/mount';

import introspectionQueryResultData from 'react/apollo/fragmentTypes.json';

const isClientSide = typeof window !== 'undefined';

const { data: { GRAPHQL_ENDPOINT } } = sharify;

const httpLink = createHttpLink({ uri: GRAPHQL_ENDPOINT });

const fragmentMatcher = new IntrospectionFragmentMatcher({
  introspectionQueryResultData: {
    __schema: {
      types: introspectionQueryResultData,
    },
  },
});

export const initApolloClient = (token) => {
  if (isClientSide && window.__APOLLO_CLIENT__) {
    return window.__APOLLO_CLIENT__;
  }

  const cache = new InMemoryCache({ fragmentMatcher });

  if (isClientSide && window.__APOLLO_STATE__) {
    cache.restore(window.__APOLLO_STATE__);
  }

  const { data: { X_APP_TOKEN, CURRENT_USER } } = sharify;

  const authLink = setContext((_, { headers }) => {
    const X_AUTH_TOKEN = (
      token || (isClientSide && CURRENT_USER && CURRENT_USER.authentication_token) || ''
    );

    return {
      headers: {
        ...headers,
        'X-AUTH-TOKEN': X_AUTH_TOKEN,
        'X-APP-TOKEN': X_APP_TOKEN,
      },
    };
  });

  const link = authLink.concat(httpLink);

  const client = new ApolloClient({
    ssrMode: !isClientSide,
    link,
    cache,
  });

  if (isClientSide) {
    window.__APOLLO_CLIENT__ = client;
  }

  return client;
};

if (isClientSide) {
  initApolloClient();
}

export const wrapWithApolloProvider = (client = isClientSide && window.__APOLLO_CLIENT__) =>
  (Component, props = {}) => (
    <ApolloProvider client={client}>
      <Component {...props} />
    </ApolloProvider>
  );

export const mountWithApolloProvider = (Component, props = {}, mountNode) => {
  if (!mountNode) return null;

  const client = initApolloClient();
  const WrappedComponent = wrapWithApolloProvider(client)(Component, props);

  return mount(WrappedComponent, mountNode);
};
