# How AI was used in this project

Claude Opus with high effort was used as a tool to help for faster iteration, improve the concept, initialize parts of the codebase, refactor and create and improve documentation.

## Validating ideas and concepts

Ideas were bounced off Claude to validate and refine them. Examples:

> Give me feedback on the planned folder structure for managing different environments.

> Let's discuss the approach between using symlinks and using terragrunt.

## Improving documentation

Claude was allowed to draft the `README.md` and write comments in the code. Documentation was then reviewed and correct/changed as needed. Examples:

> Update the @README.md according to the latest changes of this branch.

> Look over the code and add comments if sections need clarification.

> Split up @README.md. Keep generic information about the repository in the README.md and create a docs folder for detailed information.  


## Refactoring

Claude was given instructions to refactor the codebase in certain areas and ways. Examples:

> Combine borg_passphrase_db and borg_passphrase_app into a single variable. Refactor all places where they are used.

> Plan the refactoring of the packer shell provisioning script to ansible roles/playbooks.

> Remove inline files in the cloud-init template and inject them via variables.
 
## Migrating changes

The boilerplate was developed in tandem with other projects. If changes in these projects seemed useful to the boilerplate, Claude was asked to migrate and generalize. Examples: 

> Look at the project in ../../production-project and see what changes I made there. Apply these changes to this project, but keep in mind we are working on a boilerplate. Ignore project-specific changes and focus on X, Y and Z.

> The project in ../../pet-project uses a simpler approach on provisioning server and handling backups. Apply this approach to the boilerplate.

## Debugging

Claude was used to debug and fix issues faster. Examples:

> After provisioning the database server, the app server could not be used as a bastion host to access the database server. Explore the current configuration and find possible reasons.

> Building the base image works, but the resulting image is inaccessible after deployment via SSH. Add verbose debug information during to the provisioning scripts during the build process to help identify silently failing provisioning steps.

## Initialize and create code

Initial versions of configuration and scripts were created by Claude and refined as needed.

> Create a lightweight script named `tf.sh` which helps to execute tofu in an environment folder. It should source `env.sh` before executing tofu.

> Create a dedicated database server configuration, based on the app server configuration. 