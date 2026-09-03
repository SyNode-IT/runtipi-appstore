import { expect, test, describe } from "bun:test";
import { appInfoSchema, dynamicComposeSchema } from '@runtipi/common/schemas'
import { fromError } from 'zod-validation-error';
import fs from 'node:fs'
import path from 'node:path'
import YAML from 'yaml'

const getApps = async () => {
  const appsDir = await fs.promises.readdir(path.join(process.cwd(), 'apps'))

  const appDirs = appsDir.filter((app) => {
    const stat = fs.statSync(path.join(process.cwd(), 'apps', app))
    return stat.isDirectory()
  })

  return appDirs
};

const getFile = async (app: string, file: string) => {
  const filePath = path.join(process.cwd(), 'apps', app, file)
  try {
    const file = await fs.promises.readFile(filePath, 'utf-8')
    return file
  } catch (err) {
    return null
  }
}

describe("each app should have the required files", async () => {
  const apps = await getApps()

  for (const app of apps) {
    const files = ['config.json', 'metadata/logo.jpg', 'metadata/description.md']

    for (const file of files) {
      test(`app ${app} should have ${file}`, async () => {
        const fileContent = await getFile(app, file)
        expect(fileContent).not.toBeNull()
      })
    }

    test(`app ${app} should have a compose file`, async () => {
      const legacyCompose = await getFile(app, 'docker-compose.json')
      const modernCompose = await getFile(app, 'docker-compose.yml')
      expect(legacyCompose || modernCompose).not.toBeNull()
    })
  }
})

describe("each app should have a valid config.json", async () => {
  const apps = await getApps()

  for (const app of apps) {
    test(`app ${app} should have a valid config.json`, async () => {
      const fileContent = await getFile(app, 'config.json')
      const parsed = appInfoSchema.omit({ urn: true }).safeParse(JSON.parse(fileContent || '{}'))

      if (!parsed.success) {
        const validationError = fromError(parsed.error);
        console.error(`Error parsing config.json for app ${app}:`, validationError.toString());
      }

      expect(parsed.success).toBe(true)
    })
  }
})

describe("n8n-sandbox installation secrets", () => {
  test("exposes the shared API key as a password field", async () => {
    const fileContent = await getFile('n8n-sandbox', 'config.json')
    const config = JSON.parse(fileContent || '{}')
    const apiKey = config.form_fields?.find((field: { env_variable?: string }) => field.env_variable === 'SANDBOX_API_KEYS')

    expect(apiKey?.type).toBe('password')
    expect(apiKey?.required).toBe(true)
    expect(apiKey?.min).toBeGreaterThanOrEqual(48)
    expect(config.tipi_version).toBeGreaterThanOrEqual(2)
  })
})

describe("n8n-sandbox post-install documentation", () => {
  test("documents the actual n8n override and optional SearXNG JSON setup", async () => {
    const description = await getFile('n8n-sandbox', 'metadata/description.md')

    expect(description).toContain('services:\n  n8n-2:\n    environment:')
    expect(description).toContain('N8N_SANDBOX_SERVICE_URL=http://sandbox-api:8080')
    expect(description).not.toContain('sandbox-api:<PORT')
    expect(description).toContain('N8N_SANDBOX_SERVICE_API_KEY=<clé choisie lors de l’installation>')
    expect(description).toContain('/opt/runtipi/app-data/migrated/searxng/data/settings.yml')
    expect(description).toContain('- json')
  })
})

describe("modern compose files preserve runtime semantics", () => {
  test("n8n-sandbox keeps its certificate bootstrap healthy for Runtipi", async () => {
    const fileContent = await getFile('n8n-sandbox', 'docker-compose.yml')
    expect(fileContent).not.toBeNull()

    const parsed = YAML.parse(fileContent || '')
    const certs = parsed.services?.['sandbox-certs']
    const api = parsed.services?.['sandbox-api']

    expect(parsed['x-runtipi']?.schema_version).toBe(2)
    expect(certs?.restart).toBe('unless-stopped')
    expect(certs?.command?.join(' ')).toContain('touch /tmp/certs-ready')
    expect(certs?.command?.join(' ')).toContain('tail -f /dev/null')
    expect(certs?.healthcheck?.test).toContain('test -f /tmp/certs-ready')
    expect(api?.depends_on?.['sandbox-certs']?.condition).toBe('service_healthy')
    expect(api?.['x-runtipi']?.is_main).toBe(true)
    expect(parsed.services?.['sandbox-runner-1']?.environment?.SANDBOX_RUNNER_HTTP_BASE_URL).toBe('https://sandbox-runner-1:8080')
    expect(parsed.services?.['sandbox-runner-1']?.healthcheck?.test).toContain('https://localhost:8080/readyz')
  })
})

describe("each app should have a valid compose file", async () => {
  const apps = await getApps()

  for (const app of apps) {
    test(`app ${app} should have a valid compose file`, async () => {
      const legacyCompose = await getFile(app, 'docker-compose.json')
      const modernCompose = await getFile(app, 'docker-compose.yml')

      if (modernCompose) {
        const parsed = YAML.parse(modernCompose)
        expect(parsed['x-runtipi']?.schema_version).toBeTypeOf('number')
        expect(parsed.services).toBeTypeOf('object')
        return
      }

      const parsed = dynamicComposeSchema.safeParse(JSON.parse(legacyCompose || '{}'))

      if (!parsed.success) {
        const validationError = fromError(parsed.error);
        console.error(`Error parsing compose file for app ${app}:`, validationError.toString());
      }

      expect(parsed.success).toBe(true)
    })
  }
});
