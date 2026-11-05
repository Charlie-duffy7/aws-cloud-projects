# Load Balanced Web App on AWS

Another project from my cloud computing class at USU (spring 2026). I took a Flask app, got it running on EC2, and put it behind a load balancer with an auto scaling group that can run 1 to 3 instances.

## What I did

1. Launched an Amazon Linux 2023 EC2 instance (t2.micro) and got the app running on port 80 as a systemd service so it starts on boot. That's what `setup.sh` and `follicle.service` are for.
2. Made an AMI from that instance so new instances come up with the app already on them.
3. Made a launch template using the AMI, t2.micro, and a security group that allows SSH (22) and HTTP (80).
4. Made a target group on HTTP port 80 that health checks `/`. I didn't add any instances to it by hand since the auto scaling group does that.
5. Made an internet facing Application Load Balancer in us-east-1a and us-east-1c that sends port 80 traffic to the target group.
6. Made the auto scaling group from the launch template in those same two zones and attached it to the target group. Desired 1, min 1, max 3.

The site was reachable through the load balancer's DNS name, not the instance IP.

## Issues I ran into

At first I tried serving the repo with nginx and kept getting a 403. Turns out the app is Flask, not a static site. I shut nginx off and ran Flask on port 80 instead.

After that the service kept crashing with `ModuleNotFoundError: No module named 'flask'`. I had installed Flask as my user, but the service runs as root. Installing it with `sudo pip3` fixed it.

## Things I'd tighten up

Right now the instances accept HTTP from anywhere. I'd only let traffic in from the load balancer's security group and limit SSH to my own IP. I'd also add HTTPS.

## Credit

The app itself came from my class's starter repo, [czabriskie/follicle-force-3000](https://github.com/czabriskie/follicle-force-3000) (branch 2.1). The deployment and all the AWS setup was mine.

I deleted all of it and closed my AWS account after the class.

## Screenshots

<!-- drag screenshots here -->

---

*AI note: I used Claude (an AI assistant) while building this to help with the code and debugging, and to help write this README.*
