const project = process.env.PROJECT; // your GCP project
// const tag = process.env.TAG; // an image tag (this will be automatic in the future)
const tag = require('child_process').execSync('git rev-parse --short HEAD').toString().replace(/\n$/, '');
const name = 'elm-septa';
const targetPort = 5000; // the port your app runs on
const image = `gcr.io/${project}/${name}:${tag}`;

module.exports = async ({ apps }) => {
  await apps.deploy({
    name,
    image,
    build: ".",
    replicas: 1,
    service: {
      type: "LoadBalancer",
      ports: [{ port: 80, targetPort }]
    }
  });
};
