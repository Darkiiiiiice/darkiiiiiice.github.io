

.PHONY: depends

depends:
	apt-get install -y asciidoctor
	gem install asciidoctor-rouge
	gem install asciidoctor-question
	gem install asciidoctor-mathematical
	gem install asciidoctor-katex
	gem install asciidoctor-interdoc-reftext
	gem install asciidoctor-diagram
	gem install asciidoctor-bibtex
	gem install asciidoctor-html5s


