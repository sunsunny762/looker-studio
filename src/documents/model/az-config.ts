export interface AzConfig {
    protocol: string;
    serviceName: string;
    serviceDomain: string;
    servicePath: string;
    apiVer: string;
    apiKey: string;
    method: "GET" | "POST";
  }