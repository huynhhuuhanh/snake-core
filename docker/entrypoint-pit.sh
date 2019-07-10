#!/bin/bash

# Dirty magic to enable peristent scales
export SNAKE_PYTHON_DIR=/var/lib/snake/scales
export PYTHONPATH="/var/lib/snake/scales/lib/python`python3 -c "import sys; print('{}.{}'.format(sys.version_info[0], sys.version_info[1]))"`/site-packages"

if [ "$1" = 'snake-pit' ]; then
  sed -i 's/address: 127.0.0.1/address: 0.0.0.0/' /etc/snake/snake.conf

  if [ $MONGODB_ADDRESS ] && [ $MONGODB_PORT ]; then
    sed -i "s/mongodb: \"mongodb:\/\/localhost:27017\"/mongodb: \"mongodb:\/\/$MONGODB_ADDRESS:$MONGODB_PORT\"/" /etc/snake/snake.conf
  else
    echo "Please pass values for the MONGODB_ADDRESS and MONGODB_PORT"
    exit 1
  fi

  if [ $REDIS_ADDRESS ] && [ $REDIS_PORT ]; then
    sed -i "s/backend: 'redis:\/\/localhost:6379'/backend: 'redis:\/\/$REDIS_ADDRESS:$REDIS_PORT'/" /etc/snake/snake.conf
    sed -i "s/broker: 'redis:\/\/localhost:6379\/0'/broker: 'redis:\/\/$REDIS_ADDRESS:$REDIS_PORT\/0'/" /etc/snake/snake.conf
  else
    echo "Please pass values for the REDIS_ADDRESS and REDIS_PORT"
    exit 1
  fi

  if [ $HTTP_PROXY ]; then
    sed -i "s/http_proxy: null/http_proxy: $HTTP_PROXY/" /etc/snake/snake.conf
  fi
  if [ $HTTPS_PROXY ]; then
    sed -i "s/https_proxy: null/https_proxy: $HTTPS_PROXY/" /etc/snake/snake.conf
  fi

  if [ $SNAKE_COMMAND_AUTORUNS ]; then
    sed -i "s/command_autoruns: True/command_autoruns: $SNAKE_COMMAND_AUTORUNS/" /etc/snake/snake.conf
  fi

  if [ $SNAKE_SCALES_DIR ]; then
    sed -i "s/snake_scale_dirs: ['/home/alex/Developer/snake-scales']/snake_scale_dirs: [$SNAKE_SCALES_DIR]/" /etc/snake/snake.conf
  fi

  if [ $SNAKE_STRIP_EXTENSION ]; then
    sed -i "s/strip_extensions: ['inactive', 'infected', 'safety']/strip_extensions: [$SNAKE_STRIP_EXTENSION]/" /etc/snake/snake.conf
  fi

  if [ $SNAKE_ZIP_PASSWORDS ]; then
    sed -i "s/zip_passwords: ['inactive', 'infected', 'password']/zip_passwords: [$SNAKE_ZIP_PASSWORDS]/" /etc/snake/snake.conf
  fi

  # Ensure that mountpoints are owned by us
  chown -R snaked:snaked /etc/snake
  chown -R snaked:snaked /var/db/snake
  chown -R snaked:snaked /var/lib/snake

  # Run a snake pit as snaked
  CELERYD_LOG_LEVEL="INFO"
  CELERYD_OPTS="--concurrency=8"
  exec /usr/local/bin/celery worker -A snake.worker --uid snaked --loglevel=${CELERYD_LOG_LEVEL} ${CELERYD_OPTS}
fi

exec "$@"
