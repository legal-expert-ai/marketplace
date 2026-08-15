# Windows installer signing and release

The Windows installer is built, Authenticode-signed, attested and published by
`.github/workflows/release-installer.yml` whenever a tag matching
`installer-v*` is pushed. The workflow accepts only exact semantic versions such
as `installer-v1.0.2`.

The signing key is kept by Azure Artifact Signing. GitHub Actions authenticates
through OpenID Connect (OIDC), so no `.pfx` file or long-lived Azure client secret
is stored in GitHub.

## One-time Azure setup

1. Create an Azure Artifact Signing account and complete organization identity
   validation.
2. Create a **Public Trust** certificate profile. A Private Trust profile will
   not be trusted automatically on customer Windows computers.
3. Create an Entra application/service principal for this workflow and add a
   federated credential with:
   - issuer: `https://token.actions.githubusercontent.com`;
   - subject:
     `repo:legal-expert-ai@316954150/marketplace@1332250650:environment:windows-signing`;
   - audience: `api://AzureADTokenExchange`.
   The immutable organization and repository IDs in the subject prevent an
   identically named repository from inheriting this trust if names are reused.
4. Grant that principal the `Artifact Signing Certificate Profile Signer` role
   on the certificate profile (or, if necessary, on the signing account).

Official setup documentation:

- <https://learn.microsoft.com/azure/artifact-signing/quickstart-portal>
- <https://learn.microsoft.com/azure/artifact-signing/how-to-signing-integrations>
- <https://github.com/Azure/artifact-signing-action/blob/main/docs/OIDC.md>

## One-time GitHub setup

Create a GitHub environment named `windows-signing`. Restrict its deployment
tags to `installer-v*`; optionally require a reviewer for production releases.
Also add a repository ruleset so only release maintainers can create tags that
match `installer-v*`. Together, the tag ruleset and protected environment keep a
normal source push from reaching the signing identity.

Add these environment secrets:

- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`

Add these environment variables:

- `AZURE_ARTIFACT_SIGNING_ENDPOINT` = `https://weu.codesigning.azure.net/`
- `AZURE_ARTIFACT_SIGNING_ACCOUNT_NAME` = `le-signing-account`
- `AZURE_ARTIFACT_SIGNING_CERTIFICATE_PROFILE_NAME` =
  `legal-expert-public-trust`

## Publishing a release

Merge the release commit to `main`, then tag that exact commit:

```bash
git tag installer-v1.0.2
git push origin installer-v1.0.2
```

The version is derived from the tag and passed to both Inno Setup and the
embedded PowerShell bootstrap. Do not edit a version constant in the source.

The workflow will:

1. validate the tag and test the plugin and installer bootstrap;
2. build `LegalExpertSetup.exe` with the pinned Inno Setup version;
3. sign it with SHA-256 and an RFC 3161 timestamp;
4. fail unless Windows reports a valid Authenticode signature and timestamp;
5. generate the checksum from the final signed bytes;
6. create a GitHub build-provenance attestation;
7. upload the executable and checksum to the matching GitHub release.

Pull requests and normal `main`/`stable` pushes also compile an unsigned test
installer in `validate.yml`, so Inno Setup errors are caught before a release
tag is created. Only the tag workflow can access the signing environment.

Re-running the workflow is safe: existing release assets are replaced with the
newly verified artifacts. Never move an existing release tag to another commit;
publish a new patch version instead.

## Local verification

On Windows, after downloading the installer:

```powershell
Get-AuthenticodeSignature .\LegalExpertSetup.exe | Format-List Status,StatusMessage,SignerCertificate,TimeStamperCertificate
Get-FileHash .\LegalExpertSetup.exe -Algorithm SHA256
```

A valid Authenticode certificate identifies the publisher and protects the
installer from modification after signing. It does not guarantee that Microsoft
SmartScreen will stop showing reputation warnings immediately for a new
publisher or certificate.
