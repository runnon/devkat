# DEVKAT Web

React + Vite + TypeScript + Tailwind web app for DEVKAT — the same session dashboard and overlay tiles as the iOS app.

## Development

```bash
npm install
npm run dev
```

## Deploy to Vercel

```bash
vercel login
vercel --prod
```

Or connect the repo on [vercel.com](https://vercel.com) and set:
- **Root Directory:** `web`
- **Framework Preset:** Vite
- **Build Command:** `npm run build`
- **Output Directory:** `dist`
