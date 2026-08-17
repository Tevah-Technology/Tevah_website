const { Dropbox } = require('dropbox');

require('dotenv').config();

let dropboxClient = null;

// ============================================================
// DROPBOX CLIENT
// ============================================================

function getDropboxClient() {
  if (!dropboxClient) {
    const appKey = process.env.DROPBOX_APP_KEY;
    const appSecret = process.env.DROPBOX_APP_SECRET;
    const refreshToken = process.env.DROPBOX_REFRESH_TOKEN;

    if (!appKey || !appSecret || !refreshToken) {
      throw new Error(
        'Dropbox environment variables are missing. ' +
          'Check DROPBOX_APP_KEY, DROPBOX_APP_SECRET and ' +
          'DROPBOX_REFRESH_TOKEN in .env',
      );
    }

    dropboxClient = new Dropbox({
      clientId: appKey,
      clientSecret: appSecret,
      refreshToken: refreshToken,
    });
  }

  return dropboxClient;
}

// ============================================================
// LIST FOLDER
// ============================================================

async function listFolder(path) {
  const dbx = getDropboxClient();

  let result = await dbx.filesListFolder({
    path,
    recursive: false,
  });

  let entries = [...result.result.entries];

  while (result.result.has_more) {
    result = await dbx.filesListFolderContinue({
      cursor: result.result.cursor,
    });

    entries = [
      ...entries,
      ...result.result.entries,
    ];
  }

  return entries;
}

// ============================================================
// LIST FOLDER RECURSIVELY
// ============================================================

async function listFolderRecursive(path) {
  const dbx = getDropboxClient();

  let result = await dbx.filesListFolder({
    path,
    recursive: true,
  });

  let entries = [...result.result.entries];

  while (result.result.has_more) {
    result = await dbx.filesListFolderContinue({
      cursor: result.result.cursor,
    });

    entries = [
      ...entries,
      ...result.result.entries,
    ];
  }

  return entries;
}

// ============================================================
// GET SHARED LINKS
// ============================================================

async function getSharedLinks(path) {
  const dbx = getDropboxClient();

  try {
    const result =
      await dbx.sharingListSharedLinks({
        path,
        direct_only: true,
      });

    return result.result.links || [];
  } catch (error) {
    console.error(
      'Error getting shared links:',
      error?.error?.error_summary ||
        error.message,
    );

    return [];
  }
}

// ============================================================
// CREATE / GET SHARED LINK
// ============================================================

async function getOrCreateSharedLink(path) {
  const dbx = getDropboxClient();

  // ----------------------------------------------------------
  // CHECK EXISTING LINK
  // ----------------------------------------------------------

  const existing = await getSharedLinks(path);

  if (existing.length > 0) {
    return convertDropboxLink(
      existing[0].url,
    );
  }

  // ----------------------------------------------------------
  // CREATE NEW LINK
  // ----------------------------------------------------------

  try {
    const result =
      await dbx.sharingCreateSharedLinkWithSettings({
        path,
      });

    return convertDropboxLink(
      result.result.url,
    );
  } catch (error) {
    console.error(
      'Error creating shared link:',
      error?.error?.error_summary ||
        error.message,
    );

    return null;
  }
}

// ============================================================
// CONVERT DROPBOX LINK
// ============================================================

function convertDropboxLink(url) {
  if (!url) {
    return null;
  }

  return url
    .replace(
      'www.dropbox.com',
      'dl.dropboxusercontent.com',
    )
    .replace('?dl=0', '')
    .replace('&dl=0', '');
}

// ============================================================
// FILE TYPE
// ============================================================

function getFileType(name) {
  const extension = getExtension(name);

  const images = [
    'jpg',
    'jpeg',
    'png',
    'webp',
    'gif',
    'avif',
    'svg',
  ];

  const videos = [
    'mp4',
    'webm',
    'mov',
    'm4v',
    'avi',
    'mkv',
  ];

  if (images.includes(extension)) {
    return 'image';
  }

  if (videos.includes(extension)) {
    return 'video';
  }

  return 'file';
}

// ============================================================
// FILE EXTENSION
// ============================================================

function getExtension(name) {
  if (!name) {
    return '';
  }

  const parts = name.split('.');

  if (parts.length < 2) {
    return '';
  }

  return parts
    .pop()
    .toLowerCase();
}

// ============================================================
// CATEGORY NORMALIZATION
// ============================================================

function normalizeCategory(category) {
  const value =
    category
      .trim()
      .toUpperCase();

  switch (value) {
    case 'APP':
    case 'APPS':
    case 'APPLICATION':
    case 'APPLICATIONS':
      return 'APP';

    case 'WEBSITE':
    case 'WEBSITES':
    case 'WEB':
      return 'WEBSITE';

    case 'LOGO':
    case 'LOGOS':
    case 'BRANDING':
      return 'LOGO';

    case 'VIDEO':
    case 'VIDEOS':
      return 'VIDEO';

    case 'GRAPHIC':
    case 'GRAPHICS':
    case 'GRAPHIC DESIGN':
    case 'GRAPHIC DESIGNS':
    case 'GRAPHIC_DESIGNS':
      return 'GRAPHIC DESIGNS';

    default:
      return value;
  }
}

// ============================================================
// BUILD PROJECT FROM FILES
// ============================================================

async function buildProjectFromFiles({
  projectName,
  category,
  projectPath,
  files,
}) {
  let thumbnail = null;
  let videoUrl = null;

  const otherFiles = [];

  for (const file of files) {
    if (file['.tag'] !== 'file') {
      continue;
    }

    const extension =
      getExtension(file.name);

    const fileType =
      getFileType(file.name);

    const url =
      await getOrCreateSharedLink(
        file.path_lower,
      );

    if (!url) {
      continue;
    }

    // --------------------------------------------------------
    // THUMBNAIL
    // --------------------------------------------------------

    const isThumbnailName =
      file.name
        .toLowerCase()
        .startsWith('thumbnail');

    if (
      !thumbnail &&
      fileType === 'image'
    ) {
      thumbnail = url;

      // If explicitly named thumbnail,
      // definitely use it as thumbnail.
      if (isThumbnailName) {
        continue;
      }

      continue;
    }

    // --------------------------------------------------------
    // VIDEO
    // --------------------------------------------------------

    if (
      !videoUrl &&
      fileType === 'video'
    ) {
      videoUrl = url;
      continue;
    }

    // --------------------------------------------------------
    // OTHER FILE
    // --------------------------------------------------------

    otherFiles.push({
      name: file.name,
      url,
      type: fileType,
      extension,
    });
  }

  return {
    id:
      projectPath ||
      `${category}-${projectName}`,

    title: projectName,

    category,

    thumbnail,

    videoUrl,

    files: otherFiles,

    path: projectPath,

    isFeatured: false,
  };
}

// ============================================================
// GET PROJECT FROM PROJECT FOLDER
// ============================================================

async function getProjectFromFolder(
  projectFolder,
  category,
) {
  const projectFiles =
    await listFolder(
      projectFolder.path_lower,
    );

  return buildProjectFromFiles({
    projectName:
      projectFolder.name,

    category,

    projectPath:
      projectFolder.path_display,

    files: projectFiles,
  });
}

// ============================================================
// GET PORTFOLIO
// ============================================================

async function getPortfolio() {
  const root =
    process.env.DROPBOX_PORTFOLIO_PATH ||
    '/THEVA_PORTFOLIO';

  console.log('');
  console.log(
    '==============================================',
  );
  console.log(
    'DROPBOX PORTFOLIO',
  );
  console.log(
    '==============================================',
  );
  console.log(
    'Root:',
    root,
  );

  // ----------------------------------------------------------
  // GET CATEGORY FOLDERS
  // ----------------------------------------------------------

  const categories =
    await listFolder(root);

  console.log(
    'Root entries:',
    categories.length,
  );

  const categoryFolders =
    categories.filter(
      (entry) =>
        entry['.tag'] === 'folder',
    );

  console.log(
    'Category folders:',
    categoryFolders.map(
      (folder) => folder.name,
    ),
  );

  const projects = [];

  // ==========================================================
  // LOOP CATEGORIES
  // ==========================================================

  for (
    const categoryFolder
    of categoryFolders
  ) {
    const category =
      normalizeCategory(
        categoryFolder.name,
      );

    console.log('');
    console.log(
      '----------------------------------------------',
    );

    console.log(
      'Category:',
      categoryFolder.name,
      '=>',
      category,
    );

    console.log(
      'Path:',
      categoryFolder.path_display,
    );

    // --------------------------------------------------------
    // GET CATEGORY CONTENT
    // --------------------------------------------------------

    const categoryEntries =
      await listFolder(
        categoryFolder.path_lower,
      );

    console.log(
      'Entries:',
      categoryEntries.length,
    );

    // ========================================================
    // PROJECT FOLDER STRUCTURE
    // ========================================================

    const projectFolders =
      categoryEntries.filter(
        (entry) =>
          entry['.tag'] === 'folder',
      );

    // ========================================================
    // DIRECT FILE STRUCTURE
    // ========================================================

    const directFiles =
      categoryEntries.filter(
        (entry) =>
          entry['.tag'] === 'file',
      );

    // --------------------------------------------------------
    // STRUCTURE A
    // PROJECTS ARE FOLDERS
    // --------------------------------------------------------

    if (projectFolders.length > 0) {
      console.log(
        'Project folders:',
        projectFolders.map(
          (folder) =>
            folder.name,
        ),
      );

      for (
        const projectFolder
        of projectFolders
      ) {
        const project =
          await getProjectFromFolder(
            projectFolder,
            category,
          );

        projects.push(project);

        console.log(
          'Added project:',
          project.title,
        );
      }
    }

    // --------------------------------------------------------
    // STRUCTURE B
    // FILES ARE DIRECTLY INSIDE CATEGORY
    // --------------------------------------------------------

    if (directFiles.length > 0) {
      console.log(
        'Direct files:',
        directFiles.map(
          (file) =>
            file.name,
        ),
      );

      for (
        const file
        of directFiles
      ) {
        const fileType =
          getFileType(
            file.name,
          );

        const url =
          await getOrCreateSharedLink(
            file.path_lower,
          );

        if (!url) {
          continue;
        }

        const extension =
          getExtension(
            file.name,
          );

        // ------------------------------------------------------
        // IMAGE
        // ------------------------------------------------------

        if (
          fileType === 'image'
        ) {
          projects.push({
            id:
              file.id,

            title:
              file.name
                .replace(
                  /\.[^/.]+$/,
                  '',
                ),

            category,

            thumbnail:
              url,

            videoUrl:
              null,

            files: [
              {
                name:
                  file.name,

                url,

                type:
                  fileType,

                extension,
              },
            ],

            path:
              file.path_display,

            isFeatured:
              false,
          });

          continue;
        }

        // ------------------------------------------------------
        // VIDEO
        // ------------------------------------------------------

        if (
          fileType === 'video'
        ) {
          projects.push({
            id:
              file.id,

            title:
              file.name
                .replace(
                  /\.[^/.]+$/,
                  '',
                ),

            category,

            thumbnail:
              null,

            videoUrl:
              url,

            files: [
              {
                name:
                  file.name,

                url,

                type:
                  fileType,

                extension,
              },
            ],

            path:
              file.path_display,

            isFeatured:
              false,
          });

          continue;
        }

        // ------------------------------------------------------
        // OTHER FILE
        // ------------------------------------------------------

        projects.push({
          id:
            file.id,

          title:
            file.name
              .replace(
                /\.[^/.]+$/,
                '',
              ),

          category,

          thumbnail:
            null,

          videoUrl:
            null,

          files: [
            {
              name:
                file.name,

              url,

              type:
                fileType,

              extension,
            },
          ],

          path:
            file.path_display,

          isFeatured:
            false,
        });
      }
    }
  }

  console.log('');
  console.log(
    '==============================================',
  );
  console.log(
    'TOTAL PORTFOLIO PROJECTS:',
    projects.length,
  );
  console.log(
    '==============================================',
  );

  // ----------------------------------------------------------
  // PRINT PROJECTS
  // ----------------------------------------------------------

  projects.forEach(
    (project, index) => {
      console.log(
        `${index + 1}. ${project.title} | ${project.category}`,
      );
    },
  );

  return projects;
}

// ============================================================
// ACCOUNT INFO
// ============================================================

async function getAccountInfo() {
  const dbx =
    getDropboxClient();

  const result =
    await dbx.usersGetCurrentAccount();

  return result.result;
}

// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  getDropboxClient,
  listFolder,
  listFolderRecursive,
  getSharedLinks,
  getOrCreateSharedLink,
  getPortfolio,
  getAccountInfo,
};