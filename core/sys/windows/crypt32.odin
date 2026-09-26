#+build windows
package sys_windows

foreign import crypt32 "system:crypt32.lib"

@(default_calling_convention="system")
foreign crypt32 {
	CertOpenSystemStoreW        :: proc(hProv: HCRYPTPROV_LEGACY, szSubsystemProtocol: LPCWSTR) -> HCERTSTORE ---
	CertCloseStore              :: proc(hCertStore: HCERTSTORE, dwFlags: DWORD) -> BOOL ---
	CertEnumCertificatesInStore :: proc(hCertStore: HCERTSTORE, pPrevCertContext: ^CERT_CONTEXT) -> ^CERT_CONTEXT ---
	CertFreeCertificateContext  :: proc(pCertContext: ^CERT_CONTEXT) -> BOOL ---
}