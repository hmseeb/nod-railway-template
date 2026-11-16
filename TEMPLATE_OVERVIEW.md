# Deploy and Host Nod on Railway

Nod is an open-source personal agent from n8n labs. It has its own Linux workspace and its own Chromium browser. It can chase unpaid invoices, write call briefs from your email and calendar, watch a pricing page and tell you when it changes, cancel trials, and file paperwork. It asks before it sends anything or acts for you. It remembers what you tell it, and you can see and edit every note.

## About Hosting Nod

Nod's own self-host setup uses Docker Compose. The server controls its workspace and browser containers through the host's Docker socket. Railway has no Docker socket, so this template runs the same three upstream images as separate Railway services and connects them with a small exec relay on the private network:

- **Nod**: the server and web app, the only service with a public URL
- **Workspace**: the Linux machine where the agent runs commands (Python, Node, LibreOffice, ffmpeg, OCR, yt-dlp). Tools it installs persist.
- **Browser**: Chromium under a virtual display. Sites the agent signs in to stay signed in.
- **Postgres**: conversations, tasks, memory and the encrypted Vault

The images are built from Nod's own Dockerfiles at a pinned release (0.8.0), so a redeploy never pulls a surprise upgrade. Access, Vault and relay secrets are generated for you at deploy time.

## Common Use Cases

- A personal assistant that keeps working while your laptop is closed, reachable from the web app, the Nod desktop app, Telegram or WhatsApp
- Daily call briefs built from your inbox, calendar and the client's latest news
- Following up on unpaid invoices, unanswered client questions and expiring trials
- Recurring reports pulled from behind logins into a sheet
- Watching web pages and alerting you only when something changes

## Dependencies for Nod Hosting

- A model provider key. Anthropic, OpenAI, OpenRouter, Gemini, DeepSeek, Groq, Mistral and about 30 more work, as do OpenAI-compatible endpoints and ChatGPT sign-in
- Postgres (included)

### Deployment Dependencies

- [Nod repository](https://github.com/n8n-io/nod)
- [Nod documentation](https://nod.n8n.io/docs/)
- [Host your own server (upstream guide)](https://nod.n8n.io/docs/deploy/self-host/)
- [Template source, images and tests](https://github.com/hmseeb/nod-railway-template)

### Implementation Details

**First login (about 2 minutes after deploy)**

1. Wait until all four services are green.
2. Open the **Nod** service, go to **Variables**, and copy `NOD_AUTH_TOKEN`.
3. Open the Nod service's public URL and paste the token into the access form.
4. Follow onboarding and connect a model. A small model such as Claude Haiku or GPT mini is plenty for most errands. Nod shows estimated model costs under Usage.

One Nod server belongs to one person. Anyone holding `NOD_AUTH_TOKEN` has full access to your assistant and your connected accounts, so treat it like a password.

**Connect the desktop app**

In the Nod desktop app, choose **Connect to a server**, enter your Railway URL and `NOD_AUTH_TOKEN`. The app then uses this server's conversations, files, models and accounts.

**Apps, Telegram and WhatsApp**

Open **Apps** to connect Gmail, Slack, Notion, Linear and others. Sign-in goes through n8n's Composio proxy and returns to your Railway URL. Telegram and WhatsApp are set up under **Channels**, with no variables needed.

**Back up the Vault seed**

Saved passwords and API keys are encrypted with a key derived from `NOD_VAULT_SEED` on the Nod service. Keep a copy somewhere safe. Never change it: if it changes, every saved credential becomes unreadable. A database backup cannot recover them without it. You can instead set `NOD_VAULT_KEY` to a 32-byte base64 key, which overrides the seed.

**Custom domain**

Add the domain to the Nod service, then set `NOD_PUBLIC_URL` to the exact new origin, for example `https://nod.example.com`. Nod rejects requests for any other host, so the old Railway URL stops working.

**Optional settings (Nod service)**

- `LLM_PROVIDER`, `LLM_MODEL` and the matching key, for example `ANTHROPIC_API_KEY`: configure a model with variables instead of onboarding
- `TELEGRAM_*`, `WHATSAPP_*`: manage channels with variables instead of the app ([reference](https://nod.n8n.io/docs/deploy/configuration/))
- `NOD_ANALYTICS_ENABLED=true`: send anonymous product analytics to n8n (off by default)

**Sizing**

The agent's Linux workspace and Chromium do the heavy lifting. Upstream recommends 2 CPU cores and 8 GB of memory for the whole stack. Memory use rises when the agent runs several browser tasks at once. Hobby plan or higher.

**Differences from upstream self-host**

- Upstream puts a firewall container in front of the workspace that blocks private network addresses. That needs NET_ADMIN, which Railway does not grant. On Railway the workspace can reach your project's private network. Every service there needs a token or password, so do not add unauthenticated services to this project.
- The server reaches the Workspace and Browser through a token-checked relay instead of a Docker socket. It allows the same commands as upstream's Docker proxy and nothing more.

**Troubleshooting**

- "This host is not permitted": `NOD_PUBLIC_URL` does not match the address in your browser. Fix it after adding a custom domain.
- "The workspace is unavailable. Restart Nod before continuing.": the Workspace service was down when a task ran. Make sure it is green, then restart the Nod service.
- Desktop app shows "Setup needs another try. These settings are not supported." at the end of onboarding: a Nod 0.8.0 desktop bug in remote mode ([n8n-io/nod#947](https://github.com/n8n-io/nod/issues/947)). Your onboarding is already saved on the server. Quit and reopen the app instead of pressing Try again, or finish onboarding in a normal browser at your Railway URL.
- ChatGPT sign-in ends on a `127.0.0.1:1455` page that does not load: expected for a remote server. Copy that full address into **Callback URL** in Nod and select **Complete sign-in**. Port 1455 never needs to be public.
- Never give Workspace, Browser or Postgres a public domain.

## Why Deploy Nod on Railway?

Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying Nod on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
