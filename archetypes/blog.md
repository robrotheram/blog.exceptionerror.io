+++
author = "Robert Fletcher"
date = {{ now.Format "2006-01-02T15:04:05Z" }}
description = ""
draft = false
image = "/images/{{title}}/featured.png"
slug = "{{ title }}"
tags = ["Home", "lab", "Virtual macheines", "home-lab"]
title = "{{ .File.TranslationBaseName | replaceRE "-" " " | title }}"
+++