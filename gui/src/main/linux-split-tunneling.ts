import argvSplit from 'argv-split';
import child_process from 'child_process';
import path from 'path';
import { ILinuxSplitTunnelingApplication } from '../shared/application-types';
import {
  getDesktopEntries,
  readDesktopEntry,
  findIconPath,
  getImageDataUrl,
  shouldShowApplication,
  DesktopEntry,
} from './linux-desktop-entry';

const PROBLEMATIC_APPLICATIONS = {
  launchingInExistingProcess: [
    'brave-browser-stable',
    'chromium-browser',
    'firefox',
    'firefox-esr',
    'google-chrome-stable',
    'mate-terminal',
    'opera',
    'xfce4-terminal',
  ],
  launchingElsewhere: ['gnome-terminal'],
};

export async function launchApplication(
  app: ILinuxSplitTunnelingApplication | string,
): Promise<void> {
  const excludeArguments = await getLaunchCommand(app);
  if (excludeArguments.length > 0) {
    return new Promise((resolve, reject) => {
      const proc = child_process.spawn('mullvad-exclude', excludeArguments, { detached: true });
      proc.once('exit', (code: number) => {
        if (code === 1) {
          reject('Failed to start application');
        } else {
          resolve();
        }
      });
      setTimeout(() => {
        proc.removeAllListeners();
        resolve();
      }, 1000);
    });
  } else {
    throw new Error('Invalid application');
  }
}

async function getLaunchCommand(app: ILinuxSplitTunnelingApplication | string): Promise<string[]> {
  if (typeof app === 'object') {
    return formatExec(app.exec);
  } else if (path.extname(app) === '.desktop') {
    const entry = await readDesktopEntry(app);
    if (entry.exec !== undefined) {
      return formatExec(entry.exec);
    } else {
      throw new Error('Desktop file lacks exec property');
    }
  } else {
    return [app];
  }
}

// Removes placeholder arguments and separates command into list of strings
function formatExec(exec: string) {
  return argvSplit(exec).filter((argument: string) => !/%[cdDfFikmnNuUv]/.test(argument));
}

export async function getApplications(locale: string): Promise<ILinuxSplitTunnelingApplication[]> {
  const desktopEntryPaths = await getDesktopEntries();
  const desktopEntries: DesktopEntry[] = [];

  for (const entryPath of desktopEntryPaths) {
    try {
      desktopEntries.push(await readDesktopEntry(entryPath, locale));
    } catch (e) {
      // no-op
    }
  }

  const applications = desktopEntries
    .filter(shouldShowApplication)
    .map(addApplicationWarnings)
    .sort((a, b) => a.name.localeCompare(b.name))
    .map(replaceIconNameWithDataUrl);

  return Promise.all(applications);
}

async function replaceIconNameWithDataUrl(
  app: ILinuxSplitTunnelingApplication,
): Promise<ILinuxSplitTunnelingApplication> {
  try {
    // Either the app has no icon or it's already an absolute path.
    if (app.icon === undefined) {
      return app;
    }

    const iconPath = path.isAbsolute(app.icon) ? app.icon : await findIconPath(app.icon);
    if (iconPath === undefined) {
      return app;
    }

    return { ...app, icon: await getImageDataUrl(iconPath) };
  } catch (e) {
    return app;
  }
}

function addApplicationWarnings(
  application: ILinuxSplitTunnelingApplication,
): ILinuxSplitTunnelingApplication {
  const binaryBasename = path.basename(application.exec!.split(' ')[0]);
  if (PROBLEMATIC_APPLICATIONS.launchingInExistingProcess.includes(binaryBasename)) {
    return {
      ...application,
      warning: 'launches-in-existing-process',
    };
  } else if (PROBLEMATIC_APPLICATIONS.launchingElsewhere.includes(binaryBasename)) {
    return {
      ...application,
      warning: 'launches-elsewhere',
    };
  } else {
    return application;
  }
}
