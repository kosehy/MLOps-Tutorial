import os

import kfp
import kfp.components as comp
from kfp import dsl
from kfp import onprem
from kubernetes import client as k8s_client
from kubernetes.client.models import V1EnvVar

@dsl.pipeline(
    name="mnist using arcface",
    description="CT pipeline"
)
def mnist_pipeline():
    ENV_MANAGE_URL = V1EnvVar(name='MANAGE_URL', value='192.168.3.6:8088/send')

    data_0 = dsl.ContainerOp(
        name="load & preprocess data pipeline",
        image="kosehy/mnist-pre-data:latest",
    ).set_display_name('collect & preprocess data')\
    .apply(onprem.mount_pvc("data-pvc", volume_name="data", volume_mount_path="/data"))

    data_1 = dsl.ContainerOp(
        name="validate data pipeline",
        image="kosehy/mnist-val-data:latest",
    ).set_display_name('validate data').after(data_0)\
    .apply(onprem.mount_pvc("data-pvc", volume_name="data", volume_mount_path="/data"))

    train_model = dsl.ContainerOp(
        name="train embedding model",
        image="kosehy/mnist-train-model:latest",
    ).set_display_name('train model').after(data_1)\
    .apply(onprem.mount_pvc("data-pvc", volume_name="data", volume_mount_path="/data"))\
    .apply(onprem.mount_pvc("train-model-pvc", volume_name="train-model", volume_mount_path="/model"))

    embedding = dsl.ContainerOp(
        name="embedding data using embedding model",
        image="kosehy/mnist-embedding:latest",
    ).set_display_name('embedding').after(train_model)\
    .apply(onprem.mount_pvc("data-pvc", volume_name="data", volume_mount_path="/data"))\
    .apply(onprem.mount_pvc("train-model-pvc", volume_name="train-model", volume_mount_path="/model"))

    train_faiss = dsl.ContainerOp(
        name="train faiss",
        image="kosehy/mnist-train-faiss:latest",
    ).set_display_name('train faiss').after(embedding)\
    .apply(onprem.mount_pvc("data-pvc", volume_name="data", volume_mount_path="/data"))\
    .apply(onprem.mount_pvc("train-model-pvc", volume_name="train-model", volume_mount_path="/model"))

    analysis = dsl.ContainerOp(
        name="analysis total",
        image="kosehy/mnist-analysis:latest",
        file_outputs={
            "confusion_matrix": "/confusion_matrix.csv",
            "mlpipeline-ui-metadata": "/mlpipeline-ui-metadata.json",
            "accuracy": "/accuracy.json",
            "mlpipeline_metrics": "/mlpipelin-metrics.json"
        }
    ).add_env_variable(ENV_MANAGE_URL).set_display_name('analysis').after(train_faiss)\
    .apply(onprem.mount_pvc("data-pvc", volume_name="data", volume_mount_path="/data"))\
    .apply(onprem.mount_pvc("train-model-pvc", volume_name="train-model", volume_mount_path="/model"))

    baseline = 0.8
    with dsl.Condition(Analysis.outputs["accuracy"] > baseline) as check_deploy:
        deploy = dsl.ContainerOp(
            name="deploy mar",
            image="kosehy/msnit-deploy:latest",
        ).add_env_variable(ENV_MANAGE_URL).set_display_name('deploy').after(analysis)\
        .apply(onprem.mount_pvc("train-model-pvc", volume_name="train-model", volume_mount_path="/model"))\
        .apply(onprem.mount_pvc("deploy-model-pvc", volume_name="deploy-model", volume_mount_path="/deploy-model"))

if __name__=="__main__":
    host = "http://192.168.3.7:8089/pipeline"
    namespace = "admin"
    
    pipeline_name = "Mnist"
    pipeline_package_path = "pipeline.zip"
    version = "v0.0"

    experiment_name = "For Develop"
    run_name = "kubeflow pipeline test {}".format(version)

    client = kfp.Client(host=host, namespace=namespace)
    kfp.compiler.Compiler().compile(mnist_pipeline, pipeline_package_path)

    pipeline_id = client.get_pipeline_id(pipeline_name)
    if pipeline_id:
        client.upload_pipeline_version(
            pipeline_package_path=pipeline_package_path,
            pipeline_version_name=version,
            pipeline_name=pipeline_name
        )
    else:
        client.upload_pipeline(
            pipeline_package_path=pipeline_package_path,
            pipeline_name=pipeline_name
        )

    experiment = client.create_experiment(name=experiment_name, namespace=namespace)
    run = client.run_pipeline(experiment.id, run_name, pipeline_package_path)