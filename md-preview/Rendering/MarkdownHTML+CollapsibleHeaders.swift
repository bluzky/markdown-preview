//
//  MarkdownHTML+CollapsibleHeaders.swift
//  md-preview
//  Click-to-collapse heading render extension.
//

import Foundation

nonisolated extension MarkdownHTML {
  static let collapsibleHeadersStylesheet = """
    .markdown-body > .mdp-collapsible-heading {
      position: relative;
      padding-inline-start: 26px;
    }
    .markdown-body > .mdp-collapsible-heading > .mdp-collapse-toggle {
      position: absolute;
      inset-inline-start: 0;
      top: 50%;
      width: 18px;
      height: 18px;
      margin: 0;
      padding: 0;
      border: none;
      border-radius: 4px;
      background: transparent;
      appearance: none;
      transform: translateY(-50%);
      cursor: pointer;
      transition: background 0.15s ease;
    }
    .markdown-body > .mdp-collapsible-heading > .mdp-collapse-toggle:hover,
    .markdown-body > .mdp-collapsible-heading > .mdp-collapse-toggle:focus-visible {
      background: color-mix(in srgb, var(--text) 7%, transparent);
    }
    .markdown-body > .mdp-collapsible-heading > .mdp-collapse-toggle::after {
      content: "";
      position: absolute;
      inset-inline-start: 6px;
      top: calc(50% - 3px);
      width: 5px;
      height: 5px;
      border-right: 1px solid color-mix(in srgb, var(--text) 55%, transparent);
      border-bottom: 1px solid color-mix(in srgb, var(--text) 55%, transparent);
      transform: rotate(45deg);
      transition: transform 0.15s ease;
    }
    .markdown-body > .mdp-collapsible-heading[data-mdp-collapsed="true"] > .mdp-collapse-toggle::after {
      transform: rotate(-45deg);
    }
    .markdown-body > .mdp-collapsed-section {
      display: none;
    }
    """

  static let collapsibleHeadersScript = """
    <script>
    (() => {
      const headingSelector = [
        'article.markdown-body > h1',
        'article.markdown-body > h2',
        'article.markdown-body > h3',
        'article.markdown-body > h4',
        'article.markdown-body > h5',
        'article.markdown-body > h6'
      ].join(',');

      function headingLevel(heading) {
        return Number(heading.tagName.slice(1));
      }

      function sectionNodes(heading) {
        const level = headingLevel(heading);
        const nodes = [];
        let node = heading.nextElementSibling;
        while (node) {
          if (/^H[1-6]$/.test(node.tagName) && headingLevel(node) <= level) break;
          nodes.push(node);
          node = node.nextElementSibling;
        }
        return nodes;
      }

      function setCollapsed(heading, collapsed) {
        heading.dataset.mdpCollapsed = collapsed ? 'true' : 'false';
        heading.querySelector(':scope > .mdp-collapse-toggle')
          ?.setAttribute('aria-expanded', collapsed ? 'false' : 'true');
        for (const node of sectionNodes(heading)) {
          node.classList.toggle('mdp-collapsed-section', collapsed);
        }
        window.MdPreviewHost?.pushHeight?.();
      }

      function toggle(heading) {
        setCollapsed(heading, heading.dataset.mdpCollapsed !== 'true');
      }

      function setup(root) {
        for (const heading of root.querySelectorAll(headingSelector)) {
          if (heading.dataset.mdpCollapseReady === 'true') continue;
          heading.dataset.mdpCollapseReady = 'true';
          heading.dataset.mdpCollapsed = 'false';
          heading.classList.add('mdp-collapsible-heading');

          const toggleButton = document.createElement('button');
          toggleButton.type = 'button';
          toggleButton.className = 'mdp-collapse-toggle';
          toggleButton.setAttribute('aria-label', `Toggle "${heading.textContent.trim()}" section`);
          toggleButton.setAttribute('aria-expanded', 'true');
          toggleButton.addEventListener('click', () => toggle(heading));
          heading.prepend(toggleButton);
        }
      }

      window.MdPreview?.registerRenderer({
        id: 'collapsible-headings',
        render: setup
      });
      setup(document);
    })();
    </script>
    """

  struct CollapsibleHeadersExtension: MarkdownRenderExtension {
    let id = "collapsible-headings"

    func transform(_ context: RenderContext) -> RenderResult {
      let hasHeading = context.html.range(
        of: #"<h[1-6]\b"#,
        options: .regularExpression
      ) != nil
      return RenderResult(html: context.html, active: hasHeading)
    }

    func assets(mode _: VendorLoading) -> RenderAssets {
      RenderAssets(css: collapsibleHeadersStylesheet, bodyJS: collapsibleHeadersScript)
    }
  }
}
