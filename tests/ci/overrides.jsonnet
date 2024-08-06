local must_env = std.native('must_env');
{
  containerOverrides: [
    {
      name: 'nginx',
      command: ['nginx', must_env('OPTION')],
    },
  ],
}
