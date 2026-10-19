# LeetbutAI / NuCode

NuCode is an online coding platform for algorithm practice, timed contests,
assessments, and skill certifications. The application source and deployment
configuration live in the [`Pulse/`](Pulse/) submodule.

## Production site

The production frontend is available at
[nirleshsaravanan.in/nucode_on_AWS](https://nirleshsaravanan.in/nucode_on_AWS/).
It is served from a private S3 bucket through CloudFront. The application API,
database, and code runner are deployed separately; see [`Pulse/deploy/aws/README.md`](Pulse/deploy/aws/README.md)
for architecture, release steps, and operational guidance.

## Local development

See [`Pulse/README.md`](Pulse/README.md) for prerequisites, Docker Compose startup,
local service ports, and database reset instructions.

## Repository notes

- `Pulse/` is a Git submodule containing the application repository.
- Root-level `AGENTS.md` documents project architecture and development conventions.
- Never commit local environment files, deployment secrets, or runtime credentials.
