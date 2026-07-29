import { cwd } from 'node:process';

import { type UserConfig } from '@commitlint/types';
import { RuleConfigSeverity } from '@commitlint/types';
import { FsTree } from 'nx/src/generators/tree';
import { getProjects } from 'nx/src/generators/utils/project-configuration';

function findProjects(directory: string): string[] {
  return getProjects(new FsTree(directory, false))
    .values()
    .toArray()
    .map(({ name }) => name ?? '')
    .filter(Boolean);
}

export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'scope-enum': context => [
      RuleConfigSeverity.Error,
      'always',
      findProjects(context?.cwd ?? cwd()),
    ],
  },
} satisfies UserConfig;
