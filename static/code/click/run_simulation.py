#!/usr/bin/env python
# run_simulation.py

import time
import click

@click.command()
@click.argument('output', default='-', type=click.File('w'))
@click.option('-t', '--sleep-time', type=click.IntRange(min=0, max=60), default=5,
              help='Specify the time for which the simulation will run.')
@click.option('--outstring', type=str, default='Simulation Finished!',
              help='String to print to OUTPUT at the end of the simulation.')
def main(output, sleep_time, outstring):
    time.sleep(sleep_time)
    output.write(outstring + '\n')

if __name__ == '__main__':
    main()
