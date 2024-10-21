local env = std.native('env');
local must_env = std.native('must_env');
local ssm = std.native('ssm');
local tfstate = std.native('local_tfstate');
local secretsmanager_arn = std.native('secretsmanager_arn');
local isCodeDeploy = env('DEPLOYMENT_CONTROLLER', 'ECS') == 'CODE_DEPLOY';
{
  containerDefinitions: [
    {
      cpu: 0,
      environment: [
        {
          name: 'FOO_ENV',
          value: '{{ ssm `/ecspresso-test/foo` }}',
        },
        {
          name: 'FOO_ENV_FUNC',
          value: ssm('/ecspresso-test/foo'),
        },
        {
          name: 'OUTPUT_FOO',
          value: tfstate('output.foo'),
        },
        {
          name: 'BAZ_ARN',
          value: '{{ secretsmanager_arn `ecspresso-test/baz` }}',
        },
        {
          name: 'BAZ_ARN_FUNC',
          value: secretsmanager_arn('ecspresso-test/baz'),
        },
      ],
      essential: true,
      image: 'nginx:' + env('NGINX_VERSION', 'latest'),
      logConfiguration: {
        logDriver: 'awslogs',
        options: {
          'awslogs-create-group': 'true',
          'awslogs-group': 'ecspresso-test',
          'awslogs-region': 'ap-northeast-1',
          'awslogs-stream-prefix': 'nginx',
        },
      },
      mountPoints: [],
      name: 'nginx',
      portMappings: [
        {
          containerPort: 80,
          hostPort: 80,
          protocol: 'tcp',
        },
      ],
      secrets: [
        {
          name: 'FOO_SECRETS',
          valueFrom: '/ecspresso-test/foo',
        },
        {
          name: 'BAR',
          valueFrom: 'arn:aws:ssm:ap-northeast-1:%s:parameter/ecspresso-test/bar' % must_env('AWS_ACCOUNT_ID'),
        },
        {
          name: 'BAZ',
          valueFrom: secretsmanager_arn('ecspresso-test/baz'),
        },
      ],
      volumesFrom: [],
    },
    {
      essential: true,
      image: '{{ must_env `AWS_ACCOUNT_ID` }}.dkr.ecr.ap-northeast-1.amazonaws.com/bash:latest',
      logConfiguration: {
        logDriver: 'awslogs',
        options: {
          'awslogs-group': 'ecspresso-test',
          'awslogs-region': 'ap-northeast-1',
          'awslogs-stream-prefix': 'bash',
        },
      },
      name: 'bash',
      secrets: [
        {
          name: 'FOO',
          valueFrom: '/ecspresso-test/foo',
        },
        {
          name: 'BAR',
          valueFrom: 'arn:aws:ssm:ap-northeast-1:{{must_env `AWS_ACCOUNT_ID`}}:parameter/ecspresso-test/bar',
        },
        {
          name: 'BAZ_ARN',
          valueFrom: '{{ secretsmanager_arn `ecspresso-test/baz` }}',
        },
        {
          name: 'JSON_FOO',
          valueFrom: 'arn:aws:secretsmanager:ap-northeast-1:{{must_env `AWS_ACCOUNT_ID`}}:secret:ecspresso-test/json-soBS7X:foo::',
        },
        {
          name: 'JSON_VIA_SSM',
          valueFrom: '{{ secretsmanager_arn `ecspresso-test/json` }}',
        },
      ],
      mountPoints: if isCodeDeploy then null else [
        {
          containerPath: '/mnt/ebs',
          sourceVolume: 'ebs',
        },
      ],
      restartPolicy: {
        enabled: true,
        ignoredExitCodes: [ 0 ],
        restartAttemptPeriod: 60,
      },
      command: [
        'bash', '-c', 'timeout --signal=9 --preserve-status 90 tail -f /dev/null',
      ],
    },
  ],
  cpu: '256',
  ephemeralStorage: {
    sizeInGiB: 50,
  },
  executionRoleArn: 'arn:aws:iam::{{must_env `AWS_ACCOUNT_ID`}}:role/ecsTaskRole',
  family: 'ecspresso-test',
  memory: '512',
  networkMode: 'awsvpc',
  placementConstraints: [],
  requiresCompatibilities: [
    'FARGATE',
  ],
  tags: [
    {
      key: 'TaskType',
      value: 'ecspresso-test',
    },
    {
      key: 'cost-category',
      value: 'ecspresso-test',
    },
  ],
  taskRoleArn: 'arn:aws:iam::{{must_env `AWS_ACCOUNT_ID`}}:role/ecsTaskRole',
  volumes: if isCodeDeploy then null else [
    {
      name: 'ebs',
      configuredAtLaunch: true,
    },
  ],
}
