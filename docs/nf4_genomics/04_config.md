# Part 3: Resource profiling and optimization

[TODO]

---

[TODO]

### 4.3. Run the workflow to generate a resource utilization report

To have Nextflow generate the report automatically, simply add `-with-report <filename>.html` to your command line.

```bash
nextflow run main.nf -profile my_laptop -with-report report-config-1.html
```

The report is an html file, which you can download and open in your browser. You can also right click it in the file explorer on the left and click on `Show preview` in order to view it on Gitpod.

Take a few minutes to look through the report and see if you can identify some opportunities for adjusting resources.
Make sure to click on the tabs that show the utilization results as a percentage of what was allocated.
There is some [documentation](https://www.nextflow.io/docs/latest/reports.html) describing all the available features.

<!-- TODO: insert images -->

One observation is that the `GATK_JOINTGENOTYPING` seems to be very hungry for CPU, which makes sense since it performs a lot of complex calculations.
So we could try boosting that and see if it cuts down on runtime.

However, we seem to have overshot the mark with the memory allocations; all processes are only using a fraction of what we're giving them.
We should dial that back down and save some resources.

### 4.4. Adjust resource allocations for a specific process

We can specify resource allocations for a given process using the `withName` process selector.
The syntax looks like this when it's by itself in a process block:

```groovy title="Syntax"
process {
    withName: 'GATK_JOINTGENOTYPING' {
        cpus = 4
    }
}
```

Let's add that to the existing process block in the `nextflow.config` file.

```groovy title="nextflow.config" linenums="11"
process {
    // defaults for all processes
    cpus = 2
    memory = 2.GB
    // allocations for a specific process
    withName: 'GATK_JOINTGENOTYPING' {
        cpus = 4
    }
}
```

With that specified, the default settings will apply to all processes **except** the `GATK_JOINTGENOTYPING` process, which is a special snowflake that gets a lot more CPU.
Hopefully that should have an effect.

### 4.5. Run again with the modified configuration

Let's run the workflow again with the modified configuration and with the reporting flag turned on, but notice we're giving the report a different name so we can differentiate them.

```bash
nextflow run main.nf -profile my_laptop -with-report report-config-2.html
```

Once again, you probably won't notice a substantial difference in runtime, because this is such a small workload and the tools spend more time in ancillary tasks than in performing the 'real' work.

However, the second report shows that our resource utilization is more balanced now.

<!-- **TODO: screenshots?** -->

As you can see, this approach is useful when your processes have different resource requirements. It empowers you to right-size the resource allocations you set up for each process based on actual data, not guesswork.

!!!note

    This is just a tiny taster of what you can do to optimize your use of resources.
    Nextflow itself has some really neat [dynamic retry logic](https://training.nextflow.io/basic_training/debugging/#dynamic-resources-allocation) built in to retry jobs that fail due to resource limitations.
    Additionally, the Seqera Platform offers AI-driven tooling for optimizing your resource allocations automatically as well.

    We'll cover both of those approaches in an upcoming part of this training course.

That being said, there may be some constraints on what you can (or must) allocate depending on what computing executor and compute infrastructure you're using. For example, your cluster may require you to stay within certain limits that don't apply when you're running elsewhere.
