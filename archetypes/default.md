+++
author = "Robert Fletcher"
date = {{ now.Format "2006-01-02T15:04:05Z" }}
description = ""
title: '{{ replace .File.ContentBaseName `-` ` ` | title }}'
tags = ["Home", "lab", "Virtual macheines", "home-lab"]
thumbnail = "/images/{{.File.ContentBaseName }}/featured.png"
slug = "{{ .File.ContentBaseName }}"
++++++
