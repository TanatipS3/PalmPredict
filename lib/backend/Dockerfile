# AWS Lambda Python 3.12 base image
FROM public.ecr.aws/lambda/python:3.12

# Optional: install system packages if needed
# RUN yum -y install mesa-libGL && yum clean all

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Lambda handler (module.function)
CMD ["handler.lambda_handler"]
