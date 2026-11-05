# AWS Cloud Projects

Projects from my cloud computing class at Utah State University (spring 2026). Each folder has its own README with how I set it up and what broke along the way.

- **[NASA EPIC Image Pipeline](nasa-epic-serverless-pipeline/)** - Lambda pulls NASA Earth photos into S3 every 5 minutes, and SNS emails me on each upload. Uses Lambda, ECR, S3, SNS, EventBridge, and IAM.
- **[Load Balanced Web App](aws-load-balanced-web-app/)** - A Flask app on EC2 behind an Application Load Balancer, with an auto scaling group across two availability zones.
- **[Redis + DynamoDB Lazy Loading](redis-dynamodb-cache-aside/)** - A Python script that checks Redis before DynamoDB and caches what it finds.

I deleted all the AWS resources and closed the account after the class, so nothing here is live. The screenshots in each project's README show it running.

---

*AI note: I used Claude (an AI assistant) while building these projects to help with the code and debugging, and to help write the READMEs.*
