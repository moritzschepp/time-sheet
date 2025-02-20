# TimeSheet

This gem allows you to parse a spreadsheet with time tracking information to
generate various statistics suitable for invoices and project effort estimates.

## Changelog

v1.0.0

* input files need to be .xlsx files now because we needed to replace the
  spreadsheet parser, see [#1](https://github.com/moritzschepp/time-sheet/issues/1)

v0.9.0

* introduced employee data column: To use it, add a column "employee" to the
  spreadsheets and use flag `-e` to filter by it. If employee is not set, it
  falls back to "Me".

## Installation

```bash
gem install time-sheet
```

## Usage

The gem bundles an executable which includes a help command, just run
`time-sheet.rb --help`. As an example spreadsheet, have a look at
[the sheet we use for tests](https://github.com/moritzschepp/time-sheet/raw/master/spec/data/time_log.xls).

A config file at `~/.time-sheet.conf` is read if it exists. The only possible
option is `location: /path/to/excel/sheets`. It can be specified multiple times.

### Processing data with other tools

You can simply let the tool output a full list of time entries that are easy to
process with other tools. For example a python script `process.py` like this

~~~python
import sys
from io import StringIO
import datetime
import pandas as pd

data = sys.stdin.readlines()
data = StringIO("\n".join(data))
df = pd.read_csv(data,
  sep='|',
  names=['date', 'start', 'end', 'minutes', 'project', 'activity', 'description'],
  converters={
    'date': lambda x: datetime.datetime.strptime(x, '%Y-%m-%d').date(),
    'start': lambda x: datetime.datetime.strptime(x, '%H:%M').time(),
    'end': lambda x: datetime.datetime.strptime(x, '%H:%M').time()
  }
)

# ... your processing
~~~

could be used to read the data into a pandas dataframe like this:

~~~bash
time-sheet.rb --trim | ./process.py
~~~

Attention: unfortunately, the python debugger `pdb` (as well as `ipdb`) doesn't
work out of the box with scripts that make use of data via STDIN. If you want to
use it, you have to

~~~python
sys.stdin = open('/dev/tty')
ipdb.set_trace()
~~~

We keep a loose collection of scripts in the
[scripts](https://github.com/moritzschepp/time-sheet/tree/master/scripts)
folder.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/moritzschepp/time-sheet
