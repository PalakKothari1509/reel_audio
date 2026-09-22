# Deployment checklist

1. Create a hosted HTTPS service for this `backend` folder, such as Cloud Run, Render, Fly.io, or a private server.
2. Set `OPENAI_API_KEY` in the host secret manager. Never put it in Flutter, Git, `.env` files committed to source, or APK build arguments.
3. Use the public HTTPS URL as the Flutter `IdeaLabApi.baseUrl`.
4. Add authentication before exposing the endpoint publicly. At minimum, require a per-user app token and enforce rate limits.
5. Add CORS/origin restrictions if a web client will call it.
6. Log provider request IDs and errors, but never log prompts containing private user content or provider credentials.
7. Rotate any credentials that have previously been embedded in `lib/secrets.dart` or distributed in an APK.

The Flutter client is in `lib/idea_lab_api.dart`. It sends only Idea Lab form data and receives normalized ideas; provider credentials never cross that boundary.
