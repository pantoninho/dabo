const ThemeToggler = () => {
  const toggleTheme = () => {
    let theme;
    const isSystemThemeDark = window.matchMedia(
      '(prefers-color-scheme: dark)'
    ).matches;

    if (!localStorage.theme) {
      theme = isSystemThemeDark ? 'light' : 'dark';
    } else {
      theme = localStorage.theme === 'dark' ? 'light' : 'dark';
    }

    localStorage.theme = theme;

    if (localStorage.theme === 'dark') {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }

    window.document.documentElement.style.colorScheme = theme;
  };

  return (
    <button
      onClick={toggleTheme}
      className="flex h-full w-full items-center justify-center"
    >
      <div className="h-4 w-4 rounded-full border-2 border-zinc-900 bg-white hover:bg-zinc-800 dark:border-white dark:bg-zinc-800 dark:hover:bg-white" />
    </button>
  );
};

export default ThemeToggler;
