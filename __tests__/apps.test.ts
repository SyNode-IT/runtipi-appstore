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

describe("modern compose files preserve runtime semantics", () => {
  test("n8n-sandbox keeps its one-shot certificate service", async () => {
    const fileContent = await getFile('n8n-sandbox', 'docker-compose.yml')
    expect(fileContent).not.toBeNull()

    const parsed = YAML.parse(fileContent || '')
    expect(parsed['x-runtipi']?.schema_version).toBe(2)
    expect(parsed.services?.['sandbox-certs']?.restart).toBe('no')
    expect(parsed.services?.['sandbox-api']?.['x-runtipi']?.is_main).toBe(true)
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
