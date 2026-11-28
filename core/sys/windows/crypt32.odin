#+build windows
package sys_windows

foreign import crypt32 "system:crypt32.lib"

@(default_calling_convention="system")
foreign crypt32 {
	CertOpenStore                    :: proc(lpszStoreProvider: LPCSTR, dwEncodingType: DWORD, hCryptProv: HCRYPTPROV_LEGACY, dwFlags: DWORD, pvPara: rawptr) -> HCERTSTORE ---
	CertOpenSystemStoreW             :: proc(hProv: HCRYPTPROV_LEGACY, szSubsystemProtocol: LPCWSTR) -> HCERTSTORE ---
	CertCloseStore                   :: proc(hCertStore: HCERTSTORE, dwFlags: DWORD) -> BOOL ---
	CertEnumCertificatesInStore      :: proc(hCertStore: HCERTSTORE, pPrevCertContext: ^CERT_CONTEXT) -> ^CERT_CONTEXT ---
	CertAddEncodedCertificateToStore :: proc(hCertStore: HCERTSTORE, dwCertEncodingType: DWORD, pbCertEncoded: [^]BYTE, cbCertEncoded: DWORD, dwAddDisposition: DWORD, ppCertContext: ^^CERT_CONTEXT) -> BOOL ---
	CertCreateCertificateContext     :: proc(dwCertEncodingType: DWORD, pbCertEncoded: [^]BYTE, cbCertEncoded: DWORD) -> ^CERT_CONTEXT ---
	CertFreeCertificateContext       :: proc(pCertContext: ^CERT_CONTEXT) -> BOOL ---
	CertCreateCertificateChainEngine :: proc(pConfig: ^CERT_CHAIN_ENGINE_CONFIG, phChainEngine: ^HCERTCHAINENGINE) -> BOOL ---
	CertFreeCertificateChainEngine   :: proc(hChainEngine: HCERTCHAINENGINE) ---
	CertGetCertificateChain          :: proc(hChainEngine: HCERTCHAINENGINE, pCertContext: ^CERT_CONTEXT, pTime: LPFILETIME, hAdditionalStore: HCERTSTORE, pChainPara: ^CERT_CHAIN_PARA, dwFlags: DWORD, pvReserved: LPVOID, ppChainContext: ^^CERT_CHAIN_CONTEXT) -> BOOL ---
	CertFreeCertificateChain         :: proc(pChainContext: ^CERT_CHAIN_CONTEXT) ---
	CertVerifyCertificateChainPolicy :: proc(pszPolicyOID: LPCSTR, pChainContext: ^CERT_CHAIN_CONTEXT, pPolicyPara: ^CERT_CHAIN_POLICY_PARA, pPolicyStatus: ^CERT_CHAIN_POLICY_STATUS) -> BOOL ---
}
