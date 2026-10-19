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

## AI problem generation

The AI Problem Creator supports three flows:

- **Generate Problem** sends the user's request directly to the configured AI provider to create a structured private draft.
- **Generate According to My Skills** retrieves the signed-in user's accepted submissions, solved topic and difficulty counts, and the approved problem catalogue. That database context is supplied to the provider so it can recommend an existing problem or generate a new draft.
- **Refine Problem** sends the current draft and a requested change back to the provider.

The skills-based flow is a lightweight database-backed form of retrieval-augmented generation. The current implementation does not use embeddings, a vector database, or semantic similarity search.

## Repository notes

- `Pulse/` is a Git submodule containing the application repository.
- Root-level `AGENTS.md` documents project architecture and development conventions.
- Never commit local environment files, deployment secrets, or runtime credentials.
