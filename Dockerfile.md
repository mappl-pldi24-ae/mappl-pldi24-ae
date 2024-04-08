# Docker image for experimental evaluation


The docker image is directly extracted from the earlier submission using Nix.
Only necessity and utility commands needed by the docker image, e.g., the Dockerfile, gunmake, and nano, etc., are added to the artifact repo as the docker branch. For info on 
https://github.com/mappl-pldi24-ae/mappl-pldi24-ae/compare/main...docker

# To use the docker image downloaded from Google Drive

[ANONYMOUS GOOGLE DRIVE URL]()

0. download either `mappl-pldi24-ae-tested.tar.gz` (with experimental results already reproduced) or `mappl-pldi24-ae.tar.gz` (without experimental results reproduced). `mappl-pldi24-ae-tested.tar.gz` is used as an example in this document. 

1. unzip the downloaded `.tar.gz` file into the `.tar` file.

    ```
    tar -zxf mappl-pldi24-ae-tested.tar.gz 
    ```

2. load the docker image
   
   ```
   docker load < mappl-pldi24-ae-tested.tar
   ```

3. run the docker image, enter the docker container, change the directory to `/apply-pldi24-ae/bench/PLDI`, and enter `nix-shell.` 
    
    ```
    docker run -it mappl-pldi24-ae-tested bash -c "cd /mappl-pldi24-ae/bench/PLDI && nix --extra-experimental-features nix-command --extra-experimental-features flakes develop --command fish"
    ```

4. This docker image contains experimental results reproduced.

    ```shell
    root@39f9b7ed8b03 /m/b/PLDI (docker)# tree -P "*.png"

    .
    |-- hmm
    |   `-- hmm.png
    |-- hmm2
    |   `-- hmm2.png
    |-- hmm_mixed_beta_bernoulli
    |   |-- beta-bern_32.png
    |   `-- beta-bern_64.png
    |-- hmm_mixed_beta_normal
    |   `-- beta-normal_16.png
    `-- pcfg
        |-- pcfg_0.5.png
        `-- pcfg_0.9.png

    root@39f9b7ed8b03 /m/b/PLDI (docker)# ls -all  ./*/*.png

    -rw-r--r-- 1 root root 24295 Mar 27 14:12 ./hmm/hmm.png
    -rw-r--r-- 1 root root 24473 Mar 27 14:12 ./hmm2/hmm2.png
    -rw-r--r-- 1 root root 30906 Mar 27 10:09 ./hmm_mixed_beta_bernoulli/beta-bern_32.png
    -rw-r--r-- 1 root root 32998 Mar 27 10:39 ./hmm_mixed_beta_bernoulli/beta-bern_64.png
    -rw-r--r-- 1 root root 28684 Mar 27 10:47 ./hmm_mixed_beta_normal/beta-normal_16.png
    -rw-r--r-- 1 root root 39007 Mar 27 09:11 ./pcfg/pcfg_0.5.png
    -rw-r--r-- 1 root root 39203 Mar 27 09:54 ./pcfg/pcfg_0.9.png
    ```

    To see what parameters were used:
    ```diff
    root@39f9b7ed8b03 /m/b/PLDI (docker)# git diff --color > diff.txt
    root@39f9b7ed8b03 /m/b/PLDI (docker)# cat diff.txt 
    diff --git a/bench/PLDI/hmm/Makefile b/bench/PLDI/hmm/Makefile
    index f2acfd4..d3ea233 100644
    --- a/bench/PLDI/hmm/Makefile
    +++ b/bench/PLDI/hmm/Makefile
    @@ -15,7 +15,7 @@ bench.mappl: bench.enum.sh hmm.mappl.py
        sh bench.mappl.sh 0.3 0.3 0.7 $(mappl_len)
    
    bench.perpl: bench.perpl.sh
    -	sh bench.perpl.sh $(mappl_len)
    +	sh bench.perpl.sh 16
    
    bench.plot:
        python3 plot.py \
    diff --git a/bench/PLDI/hmm2/Makefile b/bench/PLDI/hmm2/Makefile
    index 9ac9699..7e1f8dc 100644
    --- a/bench/PLDI/hmm2/Makefile
    +++ b/bench/PLDI/hmm2/Makefile
    @@ -15,7 +15,7 @@ bench.mappl: bench.enum.sh hmm2.mappl.py
        sh bench.mappl.sh 0.3 0.3 0.7 $(mappl_len)
    
    bench.perpl: bench.perpl.sh
    -	sh bench.perpl.sh $(mappl_len)
    +	sh bench.perpl.sh 16
    
    bench.plot: 
        python3 plot.py \
    diff --git a/bench/PLDI/hmm_mixed_beta_bernoulli/Makefile b/bench/PLDI/hmm_mixed_beta_bernoulli/Makefile
    index 4ae339b..b924e74 100644
    --- a/bench/PLDI/hmm_mixed_beta_bernoulli/Makefile
    +++ b/bench/PLDI/hmm_mixed_beta_bernoulli/Makefile
    @@ -1,4 +1,4 @@
    -exponent = 15
    +exponent = 12
    alpha = 1
    beta = 1
    theta_0 = 0.3
    diff --git a/bench/PLDI/hmm_mixed_beta_normal/Makefile b/bench/PLDI/hmm_mixed_beta_normal/Makefile
    index d7b74d6..3f7afa1 100644
    --- a/bench/PLDI/hmm_mixed_beta_normal/Makefile
    +++ b/bench/PLDI/hmm_mixed_beta_normal/Makefile
    @@ -1,4 +1,4 @@
    -exponent = 15
    +exponent = 12
    
    bench.is: bench.is.sh hmm_mixed.is.py
        sh bench.is.sh $(exponent) 16 1 1 0.125 0.3 0.7
    diff --git a/bench/PLDI/pcfg/Makefile b/bench/PLDI/pcfg/Makefile
    index f1a78b9..b771be6 100644
    --- a/bench/PLDI/pcfg/Makefile
    +++ b/bench/PLDI/pcfg/Makefile
    @@ -1,7 +1,7 @@
    -enum_len = 9
    -base_len = 14
    +enum_len = 8
    +base_len = 12
    dice_len = 20
    -perpl_len = 120
    +perpl_len = 60
    mappl_len = 120
    
    pcfg.hoisted.mappl: pcfg.mappl
    ```

    More info on what files were generated.

    ```shell
    oot@39f9b7ed8b03 /m/b/PLDI (docker) [1]# git status 
    On branch docker
    Your branch is up to date with 'origin/docker'.

    Changes not staged for commit:
    (use "git add <file>..." to update what will be committed)
    (use "git restore <file>..." to discard changes in working directory)
        modified:   hmm/Makefile
        modified:   hmm2/Makefile
        modified:   hmm_mixed_beta_bernoulli/Makefile
        modified:   hmm_mixed_beta_normal/Makefile
        modified:   pcfg/Makefile

    Untracked files:
    (use "git add <file>..." to include in what will be committed)
        diff.txt
        hmm/hmm-enum-sigma_0.3-theta_0.3_0.7-horizon_ub_16.csv
        hmm/hmm-enum-sigma_0.3-theta_0.3_0.7-horizon_ub_16.log.csv
        hmm/hmm-enum-sigma_0.3-theta_0.3_0.7-horizon_ub_8.csv
        hmm/hmm-enum-sigma_0.3-theta_0.3_0.7-horizon_ub_8.log.csv
        hmm/hmm-mappl-sigma_0.3-theta_0.3_0.7-horizon_ub_32.csv
        hmm/hmm-mappl-sigma_0.3-theta_0.3_0.7-horizon_ub_32.log.csv
        hmm/hmm-mappl-sigma_0.3-theta_0.3_0.7-horizon_ub_64.csv
        hmm/hmm-mappl-sigma_0.3-theta_0.3_0.7-horizon_ub_64.log.csv
        hmm/hmm-perpl.csv
        hmm/hmm.debug.mappl
        hmm/hmm.hoisted.mappl
        hmm/hmm.mappl.py
        hmm/hmm.perpl.log
        hmm/hmm.png
        hmm2/hmm2-enum-sigma_0.3-theta_0.3_0.7-horizon_ub_16.csv
        hmm2/hmm2-enum-sigma_0.3-theta_0.3_0.7-horizon_ub_16.log.csv
        hmm2/hmm2-enum-sigma_0.3-theta_0.3_0.7-horizon_ub_8.csv
        hmm2/hmm2-enum-sigma_0.3-theta_0.3_0.7-horizon_ub_8.log.csv
        hmm2/hmm2-mappl-sigma_0.3-theta_0.3_0.7-horizon_ub_32.csv
        hmm2/hmm2-mappl-sigma_0.3-theta_0.3_0.7-horizon_ub_32.log.csv
        hmm2/hmm2-mappl-sigma_0.3-theta_0.3_0.7-horizon_ub_64.csv
        hmm2/hmm2-mappl-sigma_0.3-theta_0.3_0.7-horizon_ub_64.log.csv
        hmm2/hmm2-perpl.csv
        hmm2/hmm2.debug.mappl
        hmm2/hmm2.hoisted.mappl
        hmm2/hmm2.mappl.py
        hmm2/hmm2.perpl.log
        hmm2/hmm2.png
        hmm_mixed_beta_bernoulli/beta-bern_32.png
        hmm_mixed_beta_bernoulli/beta-bern_64.png
        hmm_mixed_beta_bernoulli/hmm_mixed.debug.mappl
        hmm_mixed_beta_bernoulli/hmm_mixed.exact.horizon_32-alpha_1-beta_1-theta_0.3_0.7.log.csv
        hmm_mixed_beta_bernoulli/hmm_mixed.exact.horizon_64-alpha_1-beta_1-theta_0.3_0.7.log.csv
        hmm_mixed_beta_bernoulli/hmm_mixed.hoisted.mappl
        hmm_mixed_beta_bernoulli/hmm_mixed.is.horizon_32-exponent_ub_12-alpha_1-beta_1-theta_0.3_0.7.log.csv
        hmm_mixed_beta_bernoulli/hmm_mixed.is.horizon_64-exponent_ub_12-alpha_1-beta_1-theta_0.3_0.7.log.csv
        hmm_mixed_beta_bernoulli/hmm_mixed.mappl.horizon_32-exponent_ub_12-alpha_1-beta_1-theta_0.3_0.7.log.csv
        hmm_mixed_beta_bernoulli/hmm_mixed.mappl.horizon_64-exponent_ub_12-alpha_1-beta_1-theta_0.3_0.7.log.csv
        hmm_mixed_beta_bernoulli/hmm_mixed.mappl.py
        hmm_mixed_beta_normal/beta-normal_16.png
        hmm_mixed_beta_normal/hmm_mixed.debug.mappl
        hmm_mixed_beta_normal/hmm_mixed.hoisted.mappl
        hmm_mixed_beta_normal/hmm_mixed.is.horizon_16-exponent_ub_12-alpha_1-beta_1-sigma_0.125-theta_0.3_0.7.log.csv
        hmm_mixed_beta_normal/hmm_mixed.is.horizon_16-exponent_ub_5-alpha_1-beta_1-sigma_0.125-theta_0.3_0.7.log.csv
        hmm_mixed_beta_normal/hmm_mixed.mappl.horizon_16-exponent_ub_12-alpha_1-beta_1-sigma_0.125-theta_0.3_0.7.log.csv
        hmm_mixed_beta_normal/hmm_mixed.mappl.horizon_16-exponent_ub_5-alpha_1-beta_1-sigma_0.125-theta_0.3_0.7.log.csv
        hmm_mixed_beta_normal/hmm_mixed.mappl.py
        hmm_mixed_beta_normal/hmm_mixed.mapplwm.horizon_16-exponent_ub_-alpha_1-beta_1-sigma_0.125-theta_0.3_0.7.log.csv
        pcfg/PCFG-config_ENUM-stop_prob_0.5.csv
        pcfg/PCFG-config_ENUM-stop_prob_0.5.log.csv
        pcfg/PCFG-config_ENUM-stop_prob_0.9.csv
        pcfg/PCFG-config_ENUM-stop_prob_0.9.log.csv
        pcfg/base-config_MAPPL-stop_prob_0.5.csv
        pcfg/base-config_MAPPL-stop_prob_0.5.log.csv
        pcfg/base-config_MAPPL-stop_prob_0.9.csv
        pcfg/base-config_MAPPL-stop_prob_0.9.log.csv
        pcfg/mappl-config_MAPPL-stop_prob_0.5.csv
        pcfg/mappl-config_MAPPL-stop_prob_0.5.log.csv
        pcfg/mappl-config_MAPPL-stop_prob_0.9.csv
        pcfg/mappl-config_MAPPL-stop_prob_0.9.log.csv
        pcfg/pcfg-dice-stop_prob_0.5.csv
        pcfg/pcfg-dice-stop_prob_0.5.json
        pcfg/pcfg-dice-stop_prob_0.9.csv
        pcfg/pcfg-dice-stop_prob_0.9.json
        pcfg/pcfg-perpl.csv
        pcfg/pcfg.base.hoisted.mappl
        pcfg/pcfg.base.mappl.py
        pcfg/pcfg.debug.mappl
        pcfg/pcfg.hoisted.mappl
        pcfg/pcfg.mappl.py
        pcfg/pcfg.perpl.log
        pcfg/pcfg_0.5.png
        pcfg/pcfg_0.9.png
    ```
    
5. Please refer to `mappl-pldi24-ae/bench/PLDI/README.md` to reproduce everything. You can use either `mappl-pldi24-ae-tested.tar.gz` or `mappl-pldi24-ae.tar.gz`. `perl` may give warnning in this docker image, but it is fine.

    ```shell
    root@39f9b7ed8b03 /m/b/PLDI (docker)# perl
    perl: warning: Setting locale failed.
    perl: warning: Please check that your locale settings:
        LANGUAGE = (unset),
        LC_ALL = (unset),
        LC_CTYPE = "en_US.UTF-8",
        LANG = (unset)
        are supported and installed on your system.
    perl: warning: Falling back to the standard locale ("C").
    ```


# To use the docker image from a Dockerfile.

0. You get the docker file by either 
    - `git clone https://github.com/mappl-pldi24-ae/mappl-pldi24-ae --branch=docker`,
    - copy and paste from https://github.com/mappl-pldi24-ae/mappl-pldi24-ae/blob/docker/Dockerfile, or 
    - copy and paste from here

        ```docker
        FROM nixos/nix

        RUN git clone https://github.com/mappl-pldi24-ae/mappl-pldi24-ae --branch=docker
        WORKDIR /mappl-pldi24-ae
        RUN nix --extra-experimental-features  nix-command --extra-experimental-features flakes develop 

        # ENV LC_ALL en_US.UTF-8
        # ENV LANG en_US.UTF-8
        # ENV LANGUAGE en_US:en

        CMD ["nix", "--extra-experimental-features",  "nix-command", "--extra-experimental-features", "flakes", "develop"]
        ```

1. build the image

    ```shell
    [$] <> docker build -t mappl-pldi24-ae .
    # [+] Building 1.5s (8/8) FINISHED                                                                                                                                            docker:default
    #  => [internal] load build definition from Dockerfile                                                                                                                                  0.2s
    #  => => transferring dockerfile: 41.95kB                                                                                                                                               0.0s
    #  => [internal] load metadata for docker.io/nixos/nix:latest                                                                                                                           0.5s
    #  => [internal] load .dockerignore                                                                                                                                                     0.1s
    #  => => transferring context: 2B                                                                                                                                                       0.0s
    #  => [1/4] FROM docker.io/nixos/nix:latest@sha256:3f6c77ee4d2c82e472e64e6cd7087241dc391421a0b42c22e6849c586d5398d9                                                                     0.0s
    #  => CACHED [2/4] RUN git clone https://github.com/mappl-pldi24-ae/mappl-pldi24-ae --branch=docker                                                                                     0.0s
    #  => CACHED [3/4] WORKDIR /mappl-pldi24-ae                                                                                                                                             0.0s
    #  => CACHED [4/4] RUN nix --extra-experimental-features  nix-command --extra-experimental-features flakes develop                                                                      0.0s
    #  => exporting to image                                                                                                                                                                0.2s
    #  => => exporting layers                                                                                                                                                               0.0s
    #  => => writing image sha256:e3d674c2333b91d06b466f036b5487ee689472d879b3ef3b1fa71ea157bb4e2c                                                                                          0.0s
    #  => => naming to docker.io/library/mappl-pldi24-ae 
    ```

2. Saving a clean docker image as `mapped-pldi24-ae.tar` before running all the experiments.

    ```shell
    [$] <> docker save mappl-pldi24-ae > mappl-pldi24-ae.tar
    ```

3. run the docker image, enter the docker container, change the directory to `/mappl-pldi24-ae/bench/PLDI`, and enter `nix-shell`, either

    ```shell
    [$] <> docker run -it mappl-pldi24-ae #(and then detach by ctrl-p ctrl-q)
    [$] <> docker ps
    CONTAINER ID   IMAGE             COMMAND                  CREATED         STATUS         PORTS     NAMES
    42ff854095f5   mappl-pldi24-ae   "nix --extra-experim…"   8 hours ago     Up 8 hours               confident_sinoussi
    [$] <> docker exec -it 42ff bash -c "cd /mappl-pldi24-ae/bench/PLDI && nix --extra-experimental-features nix-command --extra-experimental-features flakes develop --command fish"
    ```
    or simply
    ```shell
    [$] <> docker run -it mappl-pldi24-ae bash -c "cd /mappl-pldi24-ae/bench/PLDI && nix --extra-experimental-features nix-command --extra-experimental-features flakes develop --command fish"
    ```

5. run all the experiments in the `nix-shell` with `/mappl-pldi24-ae/bench/PLDI/bench.sh` and please refer to `mappl-pldi24-ae/bench/PLDI/README.md` for estimation of running time for each experiment.

    ```shell
    root@39f9b7ed8b03 /m/b/PLDI (docker)# pwd
    /mappl-pldi24-ae/bench/PLDI
    root@39f9b7ed8b03 /m/b/PLDI (docker)# cat bench.sh 
    #!/bin/bash

    make -C hmm plot
    make -C hmm2 plot
    STOPPROB=0.5 make -C pcfg plot
    STOPPROB=0.9 make -C pcfg plot
    HORIZON=32 make -C hmm_mixed_beta_bernoulli plot
    HORIZON=64 make -C hmm_mixed_beta_bernoulli plot
    make -C hmm_mixed_beta_normal plot
    root@39f9b7ed8b03 /m/b/PLDI (docker)# sh bench.sh
    ```

    `perl` may give warnning in this docker image, but it's fine.
    ```shell
    root@39f9b7ed8b03 /m/b/PLDI (docker)# perl
    perl: warning: Setting locale failed.
    perl: warning: Please check that your locale settings:
        LANGUAGE = (unset),
        LC_ALL = (unset),
        LC_CTYPE = "en_US.UTF-8",
        LANG = (unset)
        are supported and installed on your system.
    perl: warning: Falling back to the standard locale ("C").
    ```

6. save the docker image:

    ```shell
    [$] <> docker commit 42ff mappl-pldi24-ae-tested
    sha256:71a36a1cd59015f205c50ba4167f132d3c8b807e083cad88d42449e8c5701283
    [$] <> docker save mappl-pldi24-ae-tested > mappl-pldi24-ae-tested.tar
    [$] <> ls -all mappl-pldi24-ae-tested.tar 
    -rw-rw-r-- 1 ... ... 8823575040 Mar 27 10:21 mappl-pldi24-ae-tested.tar
    ```
