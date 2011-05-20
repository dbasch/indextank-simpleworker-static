Example of how to create a search engine with IndexTank and SimpleWorker.

Why this is interesting: **you don't need a server**

The html page loads the search results via javascript directly from the IndexTank Public API

The index is populated by a SimpleWorker instance which you can run at simpleworker.com

**How to use this:**

Just replace your SimpleWorker and IndexTank keys in both files. You'll need your public api url for index.html, and your private url and SimpleWorker keys in worker.rb
