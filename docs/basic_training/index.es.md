---
description: Descripción general del material de formación básico de Nextflow
hide:
    - toc
---

# Bienvenido

Nos complace acompañarlo en el camino para escribir flujos de trabajo científicos reproducibles y escalables usando Nextflow. Esta guía complementa la documentación completa de Nextflow; si alguna vez tienes alguna duda, diríjete a los documentos que se encuentran en el siguiente [enlace](https://www.nextflow.io/docs/latest).

## Objetivos

Al final de este curso debería:

1. Ser competente en la escritura de scripts de Nextflow
2. Conocer los conceptos básicos de Nextflow de Canales, Procesos y Operadores
3. Comprender los flujos de trabajo en contenedores
4. Comprender las diferentes plataformas de ejecución compatibles con Nextflow
5. Conocer la comunidad y el ecosistema de Nextflow

## Sigue los videos de entrenamiento

Realizamos un evento de capacitación en línea gratuito para este curso aproximadamente cada seis meses. Los videos se transmiten a YouTube y las preguntas se manejan en la comunidad nf-core de Slack. Puedes ver la grabación del último entrenamiento ([marzo de 2024](https://nf-co.re/events/2024/training-foundational-march)) en la [lista de reproducción de YouTube](https://youtu.be/dbOKB3VRpuE?si=MYBy4-gjRfEYkVRM) aquí debajo:

<div style="text-align: center;">
    <iframe width="560" height="315" src="https://www.youtube.com/embed/watch?v=dbOKB3VRpuE&list=PL3xpfTVZLcNgLBGLAiY6Rl9fizsz-DTCT" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen="" data-ruffle-polyfilled=""></iframe>
</div>

Si el inglés no es su idioma preferido, puede resultarle útil seguir la capacitación del [evento de marzo de 2023](https://nf-co.re/events/2023/training-march-2023), que realizamos en múltiples idiomas.
Tenga en cuenta que algunas partes del material de capacitación pueden haberse actualizado desde que se registró.

-   :flag_gb: [En Inglés](https://youtube.com/playlist?list=PL3xpfTVZLcNhoWxHR0CS-7xzu5eRT8uHo)
-   :flag_in: [En Hindú](https://youtube.com/playlist?list=PL3xpfTVZLcNikun1FrSvtXW8ic32TciTJ)
-   :flag_es: [En Español](https://youtube.com/playlist?list=PL3xpfTVZLcNhSlCWVoa3GURacuLWeFc8O)
-   :flag_pt: [En Portugues](https://youtube.com/playlist?list=PL3xpfTVZLcNhi41yDYhyHitUhIcUHIbJg)
-   :flag_fr: [En Francés](https://youtube.com/playlist?list=PL3xpfTVZLcNhiv9SjhoA1EDOXj9nzIqdS)

## Descripción general

Para que comience con Nextflow lo más rápido posible, seguiremos los siguientes pasos:

1. Configurar un entorno de desarrollo para ejecutar Nextflow
2. Explorar los conceptos de Nextflow utilizando algunos flujos de trabajo básicos, incluido un análisis de RNA-Seq en varios pasos
3. Crear y use contenedores Docker para encapsular todas las dependencias del flujo de trabajo
4. Profundizar en la sintaxis central de Nextflow, incluidos canales, procesos y operadores
5. Probar escenarios de implementación en la nube y explore las capacidades de Nextflow Tower

Esto te dará una amplia comprensión de Nextflow para comenzar a escribir tus propios flujos de trabajo. ¡Esperamos que disfrutes del curso! Este es un documento en constante evolución: los comentarios siempre son bienvenidos.
